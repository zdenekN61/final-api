require 'json'

require 'final-api'

require 'rack'
require 'rack/contrib'
require 'sinatra/base'
require "sinatra/namespace"

require 'final-api/helpers'
require 'final-api/endpoint'

module FinalAPI
  class App < Sinatra::Base

    use Rack::CommonLogger
    use Raven::Rack
    use Rack::PostBodyContentTypeParser

    register FinalAPI::ErrorHandling
    set :show_exceptions, false

    register FinalAPI::Cors

    before do
      auth
      content_type 'application/json'
    end

    ## Endpoints

    register FinalAPI::Endpoint::Uptime
    register FinalAPI::Endpoint::Requests
    register FinalAPI::Endpoint::Builds
    register FinalAPI::Endpoint::Jobs
    register FinalAPI::Endpoint::DDTF

    run! if app_file == $0

    private

      def auth
        @user_name = env['HTTP_USERNAME']
        @authenticationToken = env['HTTP_AUTHENTICATIONTOKEN']

        #FIXME: temporary hack unless we support JWT auth
        @user_name ||= User.first.login
        @authenticationToken ||= 'anything'

        if @user_name.blank? or @authenticationToken.blank?
          halt 401, {:result => 'error', :message => "Invalid user credentials"}.to_json
        end

        @current_user = User.find_by_login(@user_name)
        unless @current_user
          #FIXME: currently only for debugging, should be same message as above
          halt 401, {:result => 'error', :message => "Unknown user"}.to_json
        end
      end


      def current_user
        @current_user ||= User.find_by_login(@user_name)
        @current_user
      end

      def save_and_respond(object)
        if object.save
          object.to_json
        else
          halt 500
        end
      end
  end
end
