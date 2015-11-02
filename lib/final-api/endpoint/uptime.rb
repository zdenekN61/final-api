require 'sidekiq/api'

module FinalAPI::Endpoint
  module Uptime

    def self.registered(app)
      app.get '/uptime' do
        begin
          ActiveRecord::Base.connection.execute('select 1')
          Travis.redis.ping
          unless File.exist?(Travis.config.log_file_storage_path)
            raise "Log file storage is not configured or accessible"
          end

          halt(200, { success: true }.to_json)
        rescue Exception => err
          halt(500, { success: false, msg: err.to_s}.to_json)
        end
      end
    end
  end
end
