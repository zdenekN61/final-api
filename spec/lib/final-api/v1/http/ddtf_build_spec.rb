require 'spec_helper'
require 'final-api/app'

describe FinalAPI::V1::Http::DDTF_Build do
  let(:fake_user) { double('fake_user', name: 'quux') }
  let(:params) do
    double(
            'fake_build',
            commit: 'foo',
            request: double('fake_request', message: 'bar'),
            id: 'bax',
            name: 'qux',
            build_info: 'quux',
            state: 'garply',
            created_at: 'foo',
            started_at: 'bar',
            stopped_by: fake_user,
            owner: fake_user,
            parts_groups: [],
            matrix: {},
            config: {}
    )
  end
  let(:subject) do
    FinalAPI::V1::Http::DDTF_Build.new(params)
  end
  let(:fake_step) do
    {
      :result => 'foo',
      :data => {
        :status => ''
      }
    }
  end

  context '#test_data' do
    {
      %w{passed failed Passed Failed PASSED FAILED} => 'Finished',
      %w{created Created CREATED} => 'Configured',
      %w{received Received RECEIVED} => 'Pending',
      %w{started Started STARTED} => 'Running',
      %w{canceled Canceled CANCELED} => 'Stopped',
      %w{errored Errored ERRORED} => 'Aborted',
      [nil, ''] => 'Unknown',
    }.each do |k, v|
      context "returns correct state: #{v}" do
        k.each do |state|
          it "for #{state}" do
            allow(params).to receive(:state) { state }
            expect(subject.test_data['status']).to eq v
          end
        end
      end
    end
  end

  context '#atom_response' do
    it 'returns string id' do
      allow(params).to receive(:id) { 2334568786432234 }
      expect(String === subject.atom_response[:id]).to be true
    end
  end

  context '#state2api_v1status' do
    it 'returns NotStep when bug occured' do
      fake_step[:result] = 'pending'
      fake_step[:data][:status] = nil
      expect(subject.send(:state2api_v1status, fake_step)).to eq 'NotSet'
    end

    {
      { result: 'created', data: {} } => 'NotSet',
      { result: 'blocked', data: {} } => 'NotTested',
      { result: 'passed', data: {}  } => 'Passed',
      { result: 'failed', data: {}  } => 'Failed',
      { result: 'failed', data: { status: 'known_bug'} } => 'KnownBug',
      { result: 'pending', data: { status: 'not_performed'} } => 'NotPerformed',
      { result: 'pending', data: { status: 'skipped'} } => 'Skipped',
    }.each do |k, v|
      it "returns #{v} for #{k}" do
        expect(subject.send(:state2api_v1status, k)).to eq v
      end
    end
  end

  context '#execution_logs' do
    let(:first_message) do
      {
        position: '2',
        timestamp: '2016-05-11T14:19:01.4310159Z',
        message: 'second message'
      }
    end
    let(:second_message) do
      {
        position: '1',
        timestamp: '2016-05-11T14:18:33.0714487Z',
        message: 'first message'
      }
    end
    let(:third_message) do
      {
        position: '3',
        timestamp: '2016-05-11T14:19:15.8995792Z',
        message: 'third message'
      }
    end
    let(:expected_response) do
      ['05/11/2016  2:18:33 PM: first message',
      '05/11/2016  2:19:01 PM: second message',
      '05/11/2016  2:19:15 PM: third message'].join("\n")
    end

    it 'sorts messages properly' do
      allow(params).to receive(:message) { [first_message, second_message, third_message].to_json }
      return_value = subject.execution_logs
      expect(return_value).to eq(expected_response)
    end

    context 'ignores invalid' do
      let(:time_stamp_malformed_message) do
        {
          position: '1',
          timestamp: 'not a valid date',
          message: 'message'
        }
      end
      let(:position_malformed_message) do
        {
          position: nil,
          timestamp: '2016-05-11T14:19:01.4310159Z',
          message: 'invalid position message'
        }
      end
      let(:malformed_position_expected_response) do
        ['05/11/2016  2:19:01 PM: invalid position message',
        '05/11/2016  2:19:15 PM: third message'].join("\n")
      end

      it 'position' do
        allow(params).to receive(:message) { [third_message, position_malformed_message].to_json }
        return_value = subject.execution_logs
        expect(return_value).to eq(malformed_position_expected_response)
      end
      it 'timestamp' do
        allow(params).to receive(:message) { [time_stamp_malformed_message].to_json }
        return_value = subject.execution_logs
        expect(return_value).to eq 'unknown date: message'
      end
    end
  end
end
