module TravisAPI
  module V1
    module Http
      class Build
        class Job
          include ::Travis::Api::Formats, ::Travis::Api::V1::Helpers::Legacy

          attr_reader :job

          def initialize(job)
            @job = job
          end

          def data
            {
              'id' => job.id,
              'repository_id' => job.repository_id,
              'number' => job.number,
              'config' => job.obfuscated_config.stringify_keys,
              'result' => legacy_job_result(job),
              'started_at' => format_date(job.started_at),
              'finished_at' => format_date(job.finished_at),
              'allow_failure' => job.allow_failure
            }
          end
        end
      end
    end
  end
end
