require 'spec_helper'
require 'final-api/app'

describe 'Builds' do
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



  context "GET /builds" do

    let!(:repository) { Factory(:repository) }
    let!(:build1) { Factory(:build, repository: repository) }
    let!(:build2) { Factory(:build, repository: Factory(:repository)) }

    context "when repository_id is given" do
      it 'return builds for that repository' do
        repository = build1.repository
        response = get '/builds', { repository_id: repository.id }, headers
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to eq [ FinalAPI::Builder.new(build1).data ]
      end
    end

    context "when no params are given" do
      #Build.recent does not show state :queued
      let!(:build3) { Factory(:build, repository: repository, state: :queued) }
      it "returns recent builds" do
        response = get '/builds', { }, headers
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to eq [
          FinalAPI::Builder.new(build2).data,
          FinalAPI::Builder.new(build1).data
        ]
      end
    end

    context "when repository and number is provided" do
      let!(:build3) { Factory(:build, repository: repository) }
      it "shows only build with particular number" do
        repository = build1.repository
        response = get '/builds', { repository_id: repository.id, number: build1.number }, headers
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to eq [ FinalAPI::Builder.new(build1).data ]
      end
    end

  end


  context "GET /builds/:id" do
    let!(:build) { Factory(:build) }

    context "when id not exits" do
      it "returns 404" do
        response = get "/builds/1234", {}, headers
        expect(response.status).to eq 404
      end
    end

    it 'returns build by :id' do
      response = get "/builds/#{build.id}", {}, headers
      result = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(result).to eq FinalAPI::Builder.new(build).data
    end

  end

  context 'POST /builds/:id/cancel' do
    let!(:build) {
      b = Factory(:build);
      b.update_attribute(:state, 'created')
      b.matrix.each { |m| m.update_attribute(:state, 'created') }
      b
    }
    context "when permissions are granted" do
      it 'cancels the build' do
        user.permissions.create!(repository_id: build.repository.id, pull: true, push: true)
        expect(Travis).to receive(:run_service).with(:cancel_build, user, id: build.id.to_s, source: 'api')
        response = post "/builds/#{build.id}/cancel", {}, headers
        expect(response.status).to eq 202
      end
    end

    context "when do not have permissons" do
      it "resposes 403" do
        response = post "/builds/#{build.id}/cancel", {}, headers
        expect(response.status).to eq 403
      end
    end

    context "when build is finsehd" do
      it "resposes 422" do
        build.matrix.each { |m| m.update_attribute(:state, 'passed') }
        user.permissions.create!(repository_id: build.repository.id, pull: true, push: true)
        response = post "/builds/#{build.id}/cancel", {}, headers
        expect(response.status).to eq 422
      end
    end
  end

  context 'POST /builds/:id/restart' do
    let!(:build) {
      b = Factory(:build);
      b.update_attribute(:state, 'passed')
      b.matrix.each { |m| m.update_attribute(:state, 'passed') }
      b
    }
    context "when do not have permissions" do
      it 'restarts the build' do
        response = post "/builds/#{build.id}/restart", {}, headers
        expect(response.status).to eq 403
      end
    end

    context "when permissions are granted" do
      it "schedules a restart" do
        user.permissions.create!(repository_id: build.repository.id, pull: true, push: true)
        expect(Travis).to receive(:run_service).with(:reset_model, user, build_id: build.id.to_s)
        response = post "/builds/#{build.id}/restart", {}, headers
        expect(response.status).to eq 202
      end
    end
  end


end
