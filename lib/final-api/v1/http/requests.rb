module FinalAPI
  module V1
    module Http
      class Requests
        include ::Travis::Api::Formats

        attr_reader :requests

        def initialize(requests, options = {})
          @requests = requests
        end

        def data
          requests.map { |request| Request.new(request).data }
        end

      end
    end
  end
end
