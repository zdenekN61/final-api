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

  context 'ddtf_v1_overall_states_sort' do
    it 'returns sorted states(all valid) by value' do
      states = ['Invalid','Skipped','Passed']
      sorted = subject.send(:ddtf_v1_overall_states_sort, states)
      expect(sorted.first).to eq 'Skipped'
      expect(sorted.last).to eq 'Passed'
    end

    it 'returns sorted states(+one invalid) by value' do
      states = ['Invalid','Skipped','Passed', 'Wrong_state']
      sorted = subject.send(:ddtf_v1_overall_states_sort, states)
      expect(sorted.first).to eq 'Skipped'
      expect(sorted.last).to eq 'Wrong_state'
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
end
