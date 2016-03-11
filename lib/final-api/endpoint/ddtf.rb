require 'final-api/builder'
require 'tsd_utils'

require 'final-api/endpoint/post/ddtf_tests/post_ddtf_tests'
require 'securerandom'

module FinalAPI
  module Endpoint
    # Encapsulation for DDTF routes
    module DDTF
      class << self
        def registered(app)
          app.get '/ddtf/announcements' do
            {
              # TODO: needs to be plural 'announcements' - it is array
              announcement: ['Testing system - get rid of DB4o alfa version']
            }.to_json
          end

          # /ddtf/tests?limit=20&offset=0&q=yyyy+id:+my_id
          app.get '/ddtf/tests' do
            limit = params[:limit] ? params[:limit].to_i : 20
            offset = params[:offset] ? params[:offset].to_i : 0
            builds = Build.order(Build.arel_table['created_at'].desc).limit(limit).offset(offset)
            builds = builds.ddtf_search(params[:q])

            # HACK: workaround make builds valid, could be removed later, when DB
            # will be valid
            builds.each { |b| b.sanitize }

            FinalAPI::V1::Http::DDTF_Builds.new(builds, {}).data.to_json
          end

          app.get '/ddtf/tests/:id' do
            build = Build.find(params[:id])
            FinalAPI::V1::Http::DDTF_Build.new(build, {}).test_data.to_json
          end

          app.get '/ddtf/tests/:id/parts' do
            build = Build.find(params[:id])
            FinalAPI::V1::Http::DDTF_Build.new(build, {}).parts_data.to_json
          end

          app.post '/ddtf/tests' do
            request_body = MultiJson.load(request.body.read)

            enqueue_data = TsdUtils::EnqueueData.new(request_body)

            begin
              tsd = enqueue_data.load_tsd
            rescue => err
              halt 422, { error: 'Unable to parse TSD data: ' + err.message }.to_json
            end

            halt 400, enqueue_data.errors.to_json unless enqueue_data.valid?

            build_params = PostDdtfTests.get_new_build_params(request_body, tsd)
            build = DDTF.create_build(
              build_params[:repository_id], build_params[:user_id], build_params[:config])

            halt 422, { error: 'Could not create new build' }.to_json if build.nil?
            request_body = request_body.merge('BuildId' => build.id)

            enqueue_data.normalize_runtime_config
            enqueue_data.resolve_strategy
            cluster_name = enqueue_data.clusters.first
            cluster_endpoint = FinalAPI.config.tsd_utils.clusters[cluster_name.to_sym]
            guid = format('00000000-0000-0000-0000-%012d', build.id)

            node_starter_data = {
              build_id: build.id,
              config: {
                id: guid,
                base_address: "http://local_ip_address/#{guid}",
                cluster_endpoint: cluster_endpoint,
                cluster_name: cluster_name,
                enqueued_by: request.env['HTTP_NAME']
              },
              enqueue_data: TsdUtils::EnqueueData.prepare_xml(request_body),
              node_api_uri: "http://localhost:8732/#{guid}/api/" # TODO: resolve in node starter
            }

            publisher = Travis::Amqp::Publisher.new(Travis.config.ddtf.node_queue)
            publisher.publish(node_starter_data)

            halt 200, FinalAPI::V1::Http::DDTF_Build.new(build, {}).atom_response.to_json
          end

          app.post '/ddtf/builds' do
            build = DDTF.create_build(params['repository_id'], params['user_id'], params['config'])
            halt 404 if build.nil?
            FinalAPI::Builder.new(build).data.to_json
          end

          app.post '/ddtf/builds/:build_id/jobs' do
            build = Build.lock.find(params[:build_id])
            parent_config = build.config.clone
            # just shrink size of config, we need specific TSD version for particular machine
            parent_config.delete :tsdContent
            job = build.matrix.create!(
              owner: build.owner,
              number: "#{build.number}.#{build.matrix.count + 1}",
              repository: build.repository,
              commit: build.commit,
              config: parent_config.deep_merge(params[:config])
            )
            job.receive(received_at: Time.now.utc)
            build.cached_matrix_ids = nil
            build.save!

            FinalAPI::Builder.new(job).data.to_json
          end

          # ids - ids of build separated by comma
          # otehrwise:
          # returns builds by param repository_id and you can specify:
          #   :number
          #   :event_type
          #   :after_number
          # if repository_id is not provided returns Build.recent
          app.get '/ddtf/builds' do
            params['ids'] = params['ids'].split(',') if params['ids'].is_a(String)
            result = Travis.service(:find_builds, params).run
            FinalAPI::Builder.new(result).data.to_json
          end

          app.post '/ddtf/builds/:id/cancel' do
            service = Travis.service(:cancel_ddtf_build, current_user, params.merge(source: 'api'))
            halt(403, { messages: service.messages }.to_json) unless service.authorized?
            halt(204, { messages: service.messages }.to_json) unless service.build
            Travis.run_service(:cancel_ddtf_build, current_user, id: params['id'])
            halt 202
          end

          app.post '/ddtf/builds/:id/restart' do
            service = Travis.service(:reset_model, current_user, build_id: params[:id])
            halt(403, { messages: service.messages }.to_json) unless service.accept?
            Travis.run_service(:reset_model, current_user, build_id: params['id'])
            halt 202
          end
        end

        def create_build(repository_id, user_id, config)
          ActiveRecord::Base.transaction do
            repo, commit, request = setup_build(repository_id, user_id)
            owner = request.owner

            build = Build.create!(
              repository: repo, commit: commit, request: request, config: config, owner: owner)

            postprocess_build(build)

            build
          end
        end

        def setup_build(repository_id, user_id)
          repository = Repository.find(repository_id) || Repository.first
          commit = repository.commits.create!(
            commit: SecureRandom.hex(20), branch: 'branch', committed_at: Time.now)
          request = Request.create!(
            repository: repository, owner: User.find(user_id))

          [repository, commit, request]
        end

        def postprocess_build(build)
          build.matrix.destroy_all
          build.cached_matrix_ids = nil
          build.start(started_at: Time.now.utc)
          build.save!
        end
      end
    end
  end
end
