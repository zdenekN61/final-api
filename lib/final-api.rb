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

require 'sidekiq'
require 'travis-sidekiqs'
require 'sidekiq-status'
require 'travis/support/amqp'


module FinalAPI
  class << self

    def config
      @confg ||= FinalAPI::Config.load
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
      Travis.logger.info "Starting Final-CI API in #{Travis.env}"

      Travis::Database.connect
      Log.establish_connection 'logs_database'
      Log::Part.establish_connection 'logs_database'

      Sidekiq.configure_server do |config|
        config.redis = Travis.config.redis.merge(namespace: Travis.config.sidekiq.namespace)
        config.server_middleware do |chain|
          chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
        end
        config.client_middleware do |chain|
          chain.add Sidekiq::Status::ClientMiddleware
        end
      end

      Travis::Async::Sidekiq.setup(Travis.config.redis.url, Travis.config.sidekiq)
      Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          chain.add Sidekiq::Status::ClientMiddleware
        end
      end

      Travis::Amqp.config = Travis.config.amqp

      Travis::Metrics.setup
      Travis::Notification.setup


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
