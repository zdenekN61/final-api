module FinalAPI
  module V1
    module Http
      class Builds
        include ::Travis::Api::Formats, ::Travis::Api::V1::Helpers::Legacy

        attr_reader :builds

        def initialize(builds, options = {})
          @builds = builds
        end

        def data
          builds.map { |build| Build.new(build).data }
        end

        #[
        #  'id'
        #  'repository_id'
        #  'number'
        #  'state'
        #  'result'
        #  'started_at'
        #  'finished_at'
        #  'duration'
        #  'commit'
        #  'branch'
        #  'message'
        #  'event_type'
        #]

      end
    end
  end
end
