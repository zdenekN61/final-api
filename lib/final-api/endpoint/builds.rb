require 'final-api/builder'
require 'travis/sidekiq/build_request'

module FinalAPI::Endpoint
  module Builds

    def self.registered(app)

      app.get '/builds/:id' do
        build = Travis.service(:find_build, params).run
        halt 404 if build.nil?
        FinalAPI::Builder.new(build).data.to_json
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
