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


  context 'GET /ddtf/tests' do
    it 'returns last 20 builds by default' do
      1.upto(22) do |idx|
        Factory(:build, {config: { name: idx.to_s } })
      end
      get "/ddtf/tests", {}, headers
      expect(last_response.status).to eq(200)
      response = MultiJson.load(last_response.body)
      expect(response.last['name']).to eq '3'
      expect(response.first['name']).to eq '22'
      expect(response.size).to eq 20
    end

    it 'limit results by limit param' do
      1.upto(3) do |idx|
        Factory(:build, {config: { name: idx.to_s } })
      end
      get "/ddtf/tests", { limit: 2}, headers
      expect(last_response.status).to eq(200)
      response = MultiJson.load(last_response.body)
      expect(response.size).to eq 2
    end

    it 'paginate by limit and offset params' do
      1.upto(5) do |idx|
        Factory(:build, {config: { name: idx.to_s } })
      end
      get "/ddtf/tests", { limit: 2, offset: 2}, headers
      expect(last_response.status).to eq(200)
      response = MultiJson.load(last_response.body)
      expect(response.last['name']).to eq '2'
      expect(response.first['name']).to eq '3'
      expect(response.size).to eq 2
    end

    describe 'filter by "q" param' do
      let!(:builds) do
        (1..20).map do |idx|
          Factory(:build, {config: { name: idx.to_s } })
        end
      end

      it 'search by \'nam\' and \'name\' keyword with contains operator' do
        get "/ddtf/tests", { q: 'nam: 2' }, headers
        expect(last_response.status).to eq(200)
        response1 = MultiJson.load(last_response.body)
        expect(response1.size).to eq 3 # '2', '12', '20'

        get '/ddtf/tests', { q: 'name: 2'}, headers
        expect(last_response.status).to eq(200)
        response2 = MultiJson.load(last_response.body)
        expect(response2).to eq response1
      end

      it 'search by \'nam\' and \'name\' keyword with = operator' do
        get "/ddtf/tests", { q: 'nam= 2' }, headers
        expect(last_response.status).to eq(200)
        response1 = MultiJson.load(last_response.body)
        expect(response1.size).to eq 1

        get '/ddtf/tests', { q: 'name= 2'}, headers
        expect(last_response.status).to eq(200)
        response2 = MultiJson.load(last_response.body)
        expect(response2).to eq response1
      end

      it 'serch by combination of keywords' do
        b = builds.last
        get '/ddtf/tests', { q: "name : #{b.config[:name]} id = \"#{b.id}\""}, headers
        response = MultiJson.load(last_response.body)
        expect(response.size).to eq 1
        expect(response.first['id']).to eq b.id
      end

    end

    it 'returns proper structure' do
      build = Factory(:build, {
        config: {
          name: 'TSD name',
          description: 'myDescription'
        }
      })

      get "/ddtf/tests", {}, headers
      response = MultiJson.load(last_response.body).first
      expect(response).to include({
        'id'            =>  build.id,
        'name'          => 'TSD name',
        'description'   => 'myDescription',
        'branch'        => nil,
        'build'         => nil,
        'queueName'     => nil,
        'status'        => 'passed',
        'strategy'      => nil,
        'email'         => nil,
        'startedBy'     => 'Sven Fuchs',
        'enqueuedBy'    => 'Sven Fuchs',
        'stopped'       => false,
        'stoppedBy'     => nil,
        'isTsd'         => true,
        'checkpoints'   => nil,
        'debugging'     => nil,
        'buildSignal'   => nil,
        'scenarioScript' => nil,
        'packageSource' => nil,
        'executionLogs' => '',
        'stashTSD'      => nil,
        'runtimeConfig' => [],
        'parts'         => [{ 'name' => nil, 'result' => 'created' }],
        'tags'          => [],
        'result'        => 'passed',
        'results'       => [{ 'type' => 'created', 'value' => 1.0 }]
      })
    end
  end

  context 'GET /ddtf/tests/:id' do
    it 'returns particular build converted'
  end

  context 'GET /ddtf/tests/:id/part' do
    it 'TODO ..write tests here'
  end
end
