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

    it "create build and return it's json" do
      repository = Factory(:repository)
      user = Factory(:user)
      config = {
        language: "tsd",
        env: ["MACHINE=x764 PART=1", "MACHINE=8x64 PART=1"],
        os: "windows"
      }
      payload = {
        user_id: user.id,
        repository_id: repository.id,
        config: config
      }
      post '/ddtf/builds', payload, headers
      expect(last_response.status).to eq(200)
      response = MultiJson.load(last_response.body)
      expect(response['config']['language']).to eq('tsd')
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
    it "creates jobs and returns it's json" do
      build = Factory(:build)
      repository = build.repository
      user = build.owner
      config = {
        language: "tsd",
        env: "MACHINE=x764 PART=1",
        os: "windows"
      }
      post "/ddtf/builds/#{build.id}/jobs", {config: config}, headers
      expect(last_response.status).to eq(200)
      result = MultiJson.load(last_response.body)
      expect(result['config']['env']).to eq('MACHINE=x764 PART=1')
      expect(result['config']['os']).to eq('windows')
    end

    it "returns 404 when build does not exists" do
      post "/ddtf/builds/1000/jobs", {}, headers
      expect(last_response.status).to eq(404)
    end
  end

end
