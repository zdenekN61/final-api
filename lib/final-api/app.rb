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
      #auth
      content_type 'application/json'
    end

    ## Endpoints

    register FinalAPI::Endpoint::Requests
    register FinalAPI::Endpoint::Builds
    register FinalAPI::Endpoint::Jobs
    register FinalAPI::Endpoint::DDTF

    ## Builds

    #get '/builds' do
    #  builds = Build.all.map(&:ddtf_test)
    #  Builder.data(builds).to_json
    #end


    #get '/builds/:id' do
    #  build = nil
    #  begin
    #    build = Build.find(params[:id])
    #  rescue ActiveRecord::RecordNotFound => err
    #    halt 404
    #  end
    #  Builder.data(build).to_json
    #end

    ### Jobs

    #get '/jobs/:id' do
    #  build = nil
    #  begin
    #    job = Job::Test.find(params[:id])
    #  rescue ActiveRecord::RecordNotFound => err
    #    halt 404
    #  end
    #  Builder.data(job).to_json
    #end

    #get '/jobs/:id/logs' do
    #end

    #post 'jobs/:id/test_step_results' do
    #  @test_step_result = TestStepResult.new(params)
    #  save_and_respond(@test_step_result)
    #end

    #post 'jobs/:id/test_case_results' do
    #  @test_case_result = TestCaseResult.new(params)
    #  save_and_respond(@test_case_result)
    #end

    #put 'jobs/:job_id/test_step_results/:id' do
    #end

    #####

    run! if app_file == $0

    private

      def auth
        @user_name = env['HTTP_USERNAME']
        @authenticationToken = env['HTTP_AUTHENTICATIONTOKEN']

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
