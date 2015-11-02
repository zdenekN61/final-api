require 'spec_helper'
require 'final-api/app'

describe 'Uptime' do

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



  context "GET /uptime" do
    it 'response status code 200 when no problem' do
      get '/uptime'
      expect(last_response.status).to eq 200
    end

    it 'response with {success: true}  200 when no problem' do
      get '/uptime'
      expect(JSON.load(last_response.body)).to eq({'success' => true})
    end


    it 'response status code 500 when DB dones not work' do
      expect(ActiveRecord::Base.connection).to receive(:execute).with(anything) do
        raise 'fake broken DB'
      end
      get '/uptime'
      expect(last_response.status).to eq 500
    end

    it 'response status code 500 when redis dones not work' do
      expect(Travis.redis).to receive(:ping) do
        raise 'fake broken Redis connection'
      end
      get '/uptime'
      expect(last_response.status).to eq 500
    end

    it 'response status code 500 when log are not accessible' do
      expect(Travis.config).to receive(:log_file_storage_path) {
        '/fake/broken/filesystem'
      }
      get '/uptime'
      expect(last_response.status).to eq 500
    end



  end


end
