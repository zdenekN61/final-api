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

      app.post 'builds/:id/cancel' do
        service = self.service(:cancel_build, params.merge(source: 'api'))
        halt(403, { message: "Not auth" }.to_json) unless service.authorized?
        halt(422, { message: "Cannot cancel build id: #{params[:id]}" }.to_json) unless service.can_cancel?
        Travis::Sidekiq::BuildCancellation.perform_async(
          id: params[:id],
          user_id: current_user.id,
          source: 'api'
        )
        halt 202
      end

      app.post 'builds/:id/restart' do
        service = self.service(:reset_model, build_id: params[:id])
        halt(403, { message: "Not accepted" }.to_json) unless service.accept?
        Travis::Sidekiq::BuildRestart.perform_async(id: params[:id], user_id: current_user.id)
        halt 202
      end

    end
  end
end
