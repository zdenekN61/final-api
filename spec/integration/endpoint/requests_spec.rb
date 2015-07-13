require 'spec_helper'

describe 'Requests' do
  include Rack::Test::Methods

  def app
    FinalAPI::App
  end

  let(:headers) { {
    'HTTP_ACCEPT' => 'application/json',
    'HTTP_USERNAME' => 'franta.lopata',
    'HTTP_AUTHENTICATIONTOKEN' => 'secret'
  } }



  context "GET /requests" do

    let!(:request1) { Factory(:request) }
    let!(:request2) { Factory(:request, repository: Factory(:repository)) }

    it '/requests' do
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


  context "/requests/:id_or_jid" do
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



end
