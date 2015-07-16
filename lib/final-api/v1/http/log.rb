module FinalAPI
  module V1
    module Http
      class Log
        include ::Travis::Api::Formats

        attr_reader :log, :commit, :options

        def initialize(log, options = {})
          @log = log
          @options = options
        end

        def data
          {
            'id' => log.id,
            'job_id' => log.job_id,
            'body' => log.content,
            'parts' => LogParts.new(options[:parts] || log.parts.order(:number, :id)).data
          }
        end
      end
    end
  end
end
