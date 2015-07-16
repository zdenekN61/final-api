require 'spec_helper'
require 'final-api/app'

describe 'Requests' do
  include Rack::Test::Methods

  def app
    FinalAPI::App
  end

  let!(:user) { Factory(:user) }

  let(:headers) { {
    'HTTP_ACCEPT' => 'application/json',
    'HTTP_USERNAME' => user.login,
    'HTTP_AUTHENTICATIONTOKEN' => 'secret'
  } }



  context "GET /requests" do

    let!(:request1) { Factory(:request) }
    let!(:request2) { Factory(:request, repository: Factory(:repository)) }

    it 'GET /requests' do
      repository = request1.repository
      response = get '/requests', { repository_id: repository.id}, headers
      expect(response.status).to eq 200
      result = JSON.parse(response.body)
      expect(result).to eq [ FinalAPI::Builder.new(request1).data ]
    end

    context "when repository not exists" do
      it "respose 404" do
        response = get '/requests', { }, headers
        expect(response.status).to eq 404

        response = get '/requests', { repository_id: 123456}, headers
        expect(response.status).to eq 404
      end
    end

  end


  context "GET /requests/:id_or_jid" do
    let!(:request) { Factory(:request, jid: SecureRandom.hex(12)) }

    context "when id not exits" do
      it "returns 404" do
        response = get "/requests/1234", { }, headers
        expect(response.status).to eq 404
        response = get "/requests/a12345678901", { }, headers
        expect(response.status).to eq 404
      end
    end

    it 'returns request by :id' do
      response = get "/requests/#{request.id}", { }, headers
      result = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(result).to eq FinalAPI::Builder.new(request).data
    end

    it 'returns request by :jid' do
      response = get "/requests/#{request.jid}", { }, headers
      result = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(result).to eq FinalAPI::Builder.new(request).data
    end
  end

  context "POST /requests" do
    let(:payload) { {
       ".travis.yml"=> {
         "language"=>"bash",
         "script"=>"echo 'well done!'",
         "git"=>{"no_clone"=>true}},
       "provider"=>"stash",
       "repository"=> {
         "slug"=>"test-repo",
         "name"=>"test-repo",
         "project"=>
          {"key"=>"FIN",
           "name"=>"FINAL-CI",
           "description"=>"Test framework based on travis-ci",
           "public"=>true,
           "type"=>"NORMAL"},
         "public"=>true
        },
       "refChange"=> {
         "refId"=>"refs/heads/master",
         "fromHash"=>"26889fb199985390da9c668d1399702940c44132",
         "toHash"=>"08328b76d12e956d96e5e87c1fd7cf34265828ef",
         "type"=>"UPDATE"
       }
    } }
    #FIXME
    #it "schedule a request" do
    #  scheuled_params = {
    #    type: 'api',
    #    payload: MultiJson.encode(payload.update(owner_name: user.name)),
    #    credentials: {}
    #  }
    #  expect(Travis::Sidekiq::BuildRequest).to receive(:perform_async).with(scheuled_params)
    #  result = post "/requests", payload, headers
    #end
  end


end
