require 'spec_helper'
require 'final-api/app'

require "fileutils"

describe 'Jobs' do
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



  context "GET /jobs" do

    let!(:job1) { Factory(:test) }
    let!(:job2) { Factory(:test) }

    context "when ids is given" do
      it 'return jobs for give ids' do
        response = get "/jobs?ids=#{[job1.id, job2.id].join(',')}", {}, headers
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to eq [
          FinalAPI::Builder.new(job1).data,
          FinalAPI::Builder.new(job2).data
        ]
      end
    end

    context "when queue is given" do
      it 'return jobs for give ids' do
        job2.update_attribute(:queue, 'builds.windows')
        response = get "/jobs?queue=builds.windows", {}, headers
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to eq [
          FinalAPI::Builder.new(job2).data
        ]
      end
    end

    context "when no params are given" do
      it "returns recent jobs" do
        response = get '/jobs', { }, headers
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to eq [
          FinalAPI::Builder.new(job1).data,
          FinalAPI::Builder.new(job2).data
        ]
      end
    end

  end


  context "GET /jobs/:id" do
    let!(:job) { Factory(:test) }

    context "when id not exits" do
      it "returns 404" do
        response = get "/jobs/1234", {}, headers
        expect(response.status).to eq 404
      end
    end

    it 'returns job by :id' do
      response = get "/jobs/#{job.id}", {}, headers
      result = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(result).to eq FinalAPI::Builder.new(job).data
    end

  end

  context 'POST /jobs/:id/cancel' do
    let!(:job) { Factory(:test, state: 'created'); }
    context "when permissions are granted" do
      it 'cancels the job' do
        user.permissions.create!(repository_id: job.repository.id, pull: true, push: true)
        expect(Travis).to receive(:run_service).with(:cancel_job, user, id: job.id.to_s, source: 'api')
        response = post "/jobs/#{job.id}/cancel", {}, headers
        expect(response.status).to eq 202
      end
    end

    context "when do not have permissons" do
      it "resposes 403" do
        response = post "/jobs/#{job.id}/cancel", {}, headers
        expect(response.status).to eq 403
      end
    end

    context "when job is finsehd" do
      it "resposes 422" do
        job.update_attribute(:state, 'passed')
        user.permissions.create!(repository_id: job.repository.id, pull: true, push: true)
        response = post "/jobs/#{job.id}/cancel", {}, headers
        expect(response.status).to eq 422
      end
    end
  end

  context 'POST /jobs/:id/restart' do
    let!(:job) { Factory(:test, state: 'passed'); }

    context "when do not have permissions" do
      it 'restarts the job' do
        response = post "/jobs/#{job.id}/restart", {}, headers
        expect(response.status).to eq 403
      end
    end

    context "when permissions are granted" do
      it "schedules a restart" do
        user.permissions.create!(repository_id: job.repository.id, pull: true, push: true)
        expect(Travis).to receive(:run_service).with(:reset_model, user, job_id: job.id.to_s)
        response = post "/jobs/#{job.id}/restart", {}, headers
        expect(response.status).to eq 202
      end
    end
  end

  context 'GET /jobs/:id/logs' do
    context "when parts are not deleted" do
      let!(:job) { Factory(:test, state: 'passed'); }
      let!(:log) { Log.create(job_id: job.id) }

      let!(:part1) { log.parts.create(number: 1, content: "part-1.", final: false) }
      let!(:part2) { log.parts.create(number: 3, content: "part-3.", final: true) }
      let!(:part3) { log.parts.create(number: 2, content: "part-2.", final: false) }

      it "returns current log parts" do
        response = get "/jobs/#{job.id}/logs", {}, headers
        result = JSON.parse(response.body)
        expect(result['body']).to eq "part-1.part-2.part-3."
        expect(result['parts'].map { |p| p.slice("number", "content", "final") }).to eq([
          { 'number' => 1, 'content' => 'part-1.', 'final' => false },
          { 'number' => 2, 'content' => 'part-2.', 'final' => false },
          { 'number' => 3, 'content' => 'part-3.', 'final' => true }
        ])
      end

      it "should restrict results by `after` params" do
        response = get "/jobs/#{job.id}/logs", { after: 1}, headers
        result = JSON.parse(response.body)
        expect(result['body']).to eq "part-1.part-2.part-3."
        expect(result['parts'].map { |p| p.slice("number", "content", "final") }).to eq([
          { 'number' => 2, 'content' => 'part-2.', 'final' => false },
          { 'number' => 3, 'content' => 'part-3.', 'final' => true }
        ])

      end
    end

    context "when parts are deleted" do
      let!(:log_data) { "Raw log data" }
      let!(:job) { Factory(:test, state: 'passed'); }
      let!(:log) { Log.create(job_id: job.id, aggregated_at: Time.now, archived_at: Time.now, archive_verified: true) }

      context "when accept encoding it text/plain" do
        it "returns row log" do
          require 'pp' #don't know why but it is neccessary to load pp before fakefs
          require "fakefs"
          FakeFS do
            log_file_name = "#{Travis.config.log_file_storage_path}/results_#{job.id}.txt"
            FileUtils.mkdir_p(Travis.config.log_file_storage_path)
            File.open(log_file_name, 'w+') do |w|
              w.write log_data
            end
            response = get "/jobs/#{job.id}/logs", { after: 1 }, headers.update('HTTP_ACCEPT' => 'text/plain')
            expect(response.body).to eq(log_data)
          end
        end

      end

      context "when accept encoding is application/json" do
        it "returs log with no parsts" do
          response = get "/jobs/#{job.id}/logs", { after: 1 }, headers
          result = JSON.parse(response.body)
          expect(result).to include("job_id" => job.id, "body" => '', "parts" => [])

        end
      end
    end

  end

end
