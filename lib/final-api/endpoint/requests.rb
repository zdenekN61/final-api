require 'final-api/builder'
require 'travis/sidekiq/build_request'

module FinalAPI::Endpoint
  module Requests

    def self.registered(app)

      app.get '/requests/:id_or_jid' do
        request = Travis.service(:find_request, params).run
        halt 404 if request.nil?
        FinalAPI::Builder.new(request).data.to_json
      end

      # @param repository_id
      # @param older_than
      # @param limit (or default_limit is used) - if not older_than used
      app.get '/requests' do
        result = Travis.service(:find_requests, params).run
        FinalAPI::Builder.new(result).data.to_json
      end

      app.post '/requests' do
        payload = params.dup.update(owner_name: current_user.name)
        Travis.logger.debug "Scheduling BuildRequest with payload: #{payload.inspect}"
        jid = Travis::Sidekiq::BuildRequest.perform_async(
          type: 'api',
          payload: MultiJson.encode(payload),
          credentials: {}
        )
        { jid: jid }.to_json
      end

    end
  end
end
