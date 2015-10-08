require 'final-api/app'

describe 'DDTF' do
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


  context "POST /ddtf/builds" do
    let(:repository) { Factory(:repository) }
    let(:config) do
      {
        language: "tsd",
        env: ["MACHINE=x764 PART=1", "MACHINE=8x64 PART=1"],
        os: "windows"
      }
    end
    let(:payload) do
      {
        user_id: user.id,
        repository_id: repository.id,
        config: config
      }
    end

    it "create build and return it's json" do
      post '/ddtf/builds', payload, headers
      expect(last_response.status).to eq(200)
      response = MultiJson.load(last_response.body)
      expect(response['config']['language']).to eq('tsd')
    end

    it "set build to 'started' state" do
      post '/ddtf/builds', payload, headers
      expect(last_response.status).to eq(200)
      response = MultiJson.load(last_response.body)
      expect(response['state']).to eq('started')
    end

    it 'returns 404 when user and repository not specified' do
      post '/ddtf/builds', {}, headers
      expect(last_response.status).to eq(404)
    end

    it 'returns 404 when user and repository not exists' do
      post '/ddtf/builds', {user_id: 100000, repository_id:100000}, headers
      expect(last_response.status).to eq(404)
    end

  end


  context "POST /ddtf/builds/:build_id/jobs" do
    let(:build) { Factory(:build) }
    let(:repository) { Factory(:repository) }
    let(:config) do
      {
        language: "tsd",
        env: "MACHINE=x764 PART=1",
        os: "windows"
      }
    end
    it "creates job and returns it's json" do
      post "/ddtf/builds/#{build.id}/jobs", {config: config}, headers
      expect(last_response.status).to eq(200)
      result = MultiJson.load(last_response.body)
      expect(result['config']['env']).to eq('MACHINE=x764 PART=1')
      expect(result['config']['os']).to eq('windows')
    end

    it "set job to 'received' state" do
      post "/ddtf/builds/#{build.id}/jobs", {config: config}, headers
      expect(last_response.status).to eq(200)
      result = MultiJson.load(last_response.body)
      expect(result['state']).to eq('received')
    end

    it "returns 404 when build does not exists" do
      post "/ddtf/builds/1000/jobs", {}, headers
      expect(last_response.status).to eq(404)
    end
  end

end
