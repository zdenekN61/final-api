$: << "lib"

require 'bundler/setup'
require 'final-api/config'
require 'travis'

require 'active_record'

require 'raven'
require 'metriks'
require 'metriks/reporter/graphite'

require 'final-api/ddtf'
require 'final-api/model_extensions'


module FinalAPI
  class << self

    def config
      @confg ||= FinalAPI::Config.new
    end

    def logger
      Travis.logger
    end

    def logger=(l)
      Travis.logger = l
    end

    def env
      Travis.env
    end

    def setup
      Travis::Database.connect

      logger.level = config.log_level || Logger::WARN

      if config.log_level == Logger::DEBUG
        Sidekiq.default_worker_options = { 'backtrace' => true }
      end

      if FinalAPI.config.sentry_dsn
        ::Raven.configure do |config|
          config.dsn = FinalAPI.config.sentry_dsn
          config.environments = %w[ production ]
          config.current_environment = FinalAPI.env
          config.excluded_exceptions = %w{Siatra::NotFound}
        end
      end

      Metriks::Reporter::Graphite.new(
        config.graphite.host,
        config.graphite.port,
        config.graphite.options || {}
      ) if config.graphite


    end
  end
end
