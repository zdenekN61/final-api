module FinalAPI
  module V1
    module Http
      class Jobs
        include ::Travis::Api::Formats, ::Travis::Api::V1::Helpers::Legacy

        attr_reader :jobs

        def initialize(jobs, options = {})
          @jobs = jobs
        end

        def data
          jobs.map { |job| Job.new(job).data }
        end

        #    'id'
        #    'repository_id'
        #    'number'
        #    'state'
        #    'queue'
        #    'allow_failure'
      end
    end
  end
end
