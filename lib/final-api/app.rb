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

    use Raven::Rack
    use Rack::PostBodyContentTypeParser

    register FinalAPI::ErrorHandling
    set :show_exceptions, false

    register FinalAPI::Cors

    before do
      content_type 'application/json'
    end

    ## Endpoints

    register FinalAPI::Endpoint::Requests

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

      def current_user
        @userName = env['HTTP_USERNAME']
        @current_user ||= User.find_by_name(@userName)
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
