require 'json'

require 'rack'
require 'rack/contrib'
require 'sinatra/base'
require "sinatra/namespace"

#require_relative '../final-api'

require 'final-api/builder'

module FinalAPI
  class App < Sinatra::Base

    set :protection, :origin_whitelist => FinalAPI.config.allowed_origin

    use Raven::Rack
    use Rack::PostBodyContentTypeParser

    before do
      content_type 'application/json'
      response['Access-Control-Allow-Origin'] = FinalAPI.config.allowed_origin
    end

    options "*" do
      response.headers["Allow"] = "HEAD,GET,PUT,DELETE,OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, userName, authenticationToken"
      halt HTTP_STATUS_OK
    end

    ## Requests

    get '/requests/:id_or_jid' do
      request = if params[:id_or_jid].to_s.size > 8
        Request.find_by_jid(params[:id_or_jid])
      else
        Request.find_by_id(params[:id_or_jid])
      end
      halt 404 unless request

      Builder.new(result).data
    end

    pust '/requests' do

    end

    ## Builds

    get '/builds' do
      builds = Build.all.map(&:ddtf_test)
      Builder.data(builds).to_json
    end


    get '/builds/:id' do
      build = nil
      begin
        build = Build.find(params[:id])
      rescue ActiveRecord::RecordNotFound => err
        halt 404
      end
      Builder.data(build).to_json
    end

    ## Jobs

    get '/jobs/:id' do
      build = nil
      begin
        job = Job::Test.find(params[:id])
      rescue ActiveRecord::RecordNotFound => err
        halt 404
      end
      Builder.data(job).to_json
    end

    get '/jobs/:id/logs' do
    end

    post 'jobs/:id/test_step_results' do
      @test_step_result = TestStepResult.new(params)
      save_and_respond(@test_step_result)
    end

    post 'jobs/:id/test_case_results' do
      @test_case_result = TestCaseResult.new(params)
      save_and_respond(@test_case_result)
    end

    put 'jobs/:job_id/test_step_results/:id' do
    end

    #####

    run! if app_file == $0

    private

      def save_and_respond(object)
        if object.save
          object.to_json
        else
          halt 500
        end
      end
  end
end
