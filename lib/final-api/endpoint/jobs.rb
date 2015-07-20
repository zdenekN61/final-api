require 'final-api/builder'
require 'travis/sidekiq/build_request'

module FinalAPI::Endpoint
  module Jobs

    def self.registered(app)

      #get list of jobs specified by ids, state or queue
      app.get '/jobs' do
        params["ids"] = params['ids'].split(',') if String === params['ids']
        result = Travis.service(:find_jobs, params).run
        FinalAPI::Builder.new(result).data.to_json
      end

      app.get '/jobs/:id' do
        build = Travis.service(:find_job, params).run
        halt 404 if build.nil?
        FinalAPI::Builder.new(build).data.to_json
      end

      app.post '/jobs/:id/cancel' do
        service = Travis.service(:cancel_job, current_user, params.merge(source: 'api'))
        halt(403, { messages: service.messages }.to_json) unless service.authorized?
        halt(422, { messages: service.messages }.to_json) unless service.can_cancel?
        Travis.run_service(:cancel_job, current_user, { id: params['id'], source: 'api' })
        halt 202
      end

      app.post '/jobs/:id/restart' do
        service = Travis.service(:reset_model, current_user, job_id: params[:id])
        halt(403, { messages: service.messages }.to_json) unless service.accept?
        Travis.run_service(:reset_model, current_user, job_id: params['id'])
        halt 202
      end

      app.get '/jobs/:job_id/logs' do
        log = Travis.service(:find_log, params).run
        halt 404 unless log
        if log.archived? and request.accept?('text/plain')
          content_type 'text/plain'
          log_path = File.join(Travis.config.log_file_storage_path, "results_#{log.job_id}.txt")
          halt 200, File.read(log_path)
        else
          parts = log.parts.order(:number, :id)
          parts = parts.where("number > ?", params['after'].to_i) if params['after']
          FinalAPI::Builder.new(log, params: {parts: parts}).data.to_json
        end
      end
    end
  end
end
