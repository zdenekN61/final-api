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
            'parts' => LogParts.new(options[:parts] || log.parts.order(:number, :id)).data,
            'created_at' => format_date(log.created_at),
            'updated_at' => format_date(log.updated_at),
            'aggregated_at' =>format_date(log.aggregated_at),
            'archived_at' => format_date(log.archived_at),
            'purged_at' =>format_date(log.purged_at),
            'archiving' => log.archiving
          }
        end
      end
    end
  end
end
