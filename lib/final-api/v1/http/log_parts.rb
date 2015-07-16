module FinalAPI
  module V1
    module Http
      class LogParts
        include ::Travis::Api::Formats

        attr_reader :log, :commit

        def initialize(parts, options = {})
          @parts = parts
        end

        def data
          @parts.map { |part| data_json(part) }
        end

        def data_json(part)
          {
            'id' => part.id,
            'log_id' => part.log_id,
            'number' => part.number,
            'content' => part.content,
            'final' => part.final
          }
        end
      end
    end
  end
end
