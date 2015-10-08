module FinalAPI
  module V1
    module Http
      class DDTF_Builds
        include ::Travis::Api::Formats, ::Travis::Api::V1::Helpers::Legacy

        attr_reader :builds

        def initialize(builds, options = {})
          @builds = builds
        end

        def data
          builds.map { |build| DDTF_Build.new(build).test_data }
        end

      end
    end
  end
end
