require 'final-api/builder'

module FinalAPI::Endpoint
  module DDTF

    def self.registered(app)


      app.get '/ddtf/announcements' do
        {
          #TODO: neets to be plural 'anoncements' - it is array
          announcement: [ 'Testing system - get rid of DB4o alfa version ' ]
        }.to_json
      end

      app.get '/ddtf/tests' do
        limit = params[:limit] ? params[:limit].to_i : 20
        offset = params[:offset] ? params[:offset].to_i : 0
        builds = Build.order(Build.arel_table['created_at'].desc).limit(params[:limit]).offset(offset)
        builds.each { |b| b.sanitize } # HACK: workaround make builds valid
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

      ###

      app.post '/ddtf/builds' do
        build = nil
        ActiveRecord::Base.transaction do
          repository = Repository.find(params[:repository_id]) || Repository.first
          commit = repository.commits.create!(commit: SecureRandom.hex(20), branch: 'branch', committed_at: Time.now)
          request = Request.create!(repository: repository, owner: User.find(params[:user_id]))

          build = Build.create!(
            repository: repository,
            commit: commit,
            request: request,
            config: params[:config],
            owner: request.owner
          ) #creates job matrix, which I need to destroy
          build.matrix.destroy_all
          build.cached_matrix_ids = nil
          build.start(started_at: Time.now.utc)
          build.save!
        end

        halt 404 if build.nil?
        FinalAPI::Builder.new(build).data.to_json
      end

      app.post '/ddtf/builds/:build_id/jobs' do
        build = Build.lock.find(params[:build_id])
        job = build.matrix.create!(
          owner: build.owner,
          number: "#{build.number}.#{build.matrix.count + 1}",
          config: build.config,
          repository: build.repository,
          commit: build.commit,
          config: params[:config]
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
      app.get '/builds' do
        params["ids"] = params['ids'].split(',') if String === params['ids']
        result = Travis.service(:find_builds, params).run
        FinalAPI::Builder.new(result).data.to_json
      end

      app.post '/builds/:id/cancel' do
        service = Travis.service(:cancel_build, current_user, params.merge(source: 'api'))
        halt(403, { messages: service.messages }.to_json) unless service.authorized?
        halt(422, { messages: service.messages }.to_json) unless service.can_cancel?
        Travis.run_service(:cancel_build, current_user, { id: params['id'], source: 'api' })
        halt 202
      end

      app.post '/builds/:id/restart' do
        service = Travis.service(:reset_model, current_user, build_id: params[:id])
        halt(403, { messages: service.messages }.to_json) unless service.accept?
        Travis.run_service(:reset_model, current_user, build_id: params['id'])
        halt 202
      end

    end
  end
end
