require 'spec_helper'
require 'final-api/app'

describe FinalAPI::Endpoint::DDTF do
  context "#get_proton_id_from_runtime_config" do
    it "parses protonid correctly" do
      rt = [
        {definition: 'foo', value: 'bar'},
        {definition: 'baz', value: 'qux'},
        {definition: 'protonid', value: 'quux'},
      ]
      result = FinalAPI::Endpoint::DDTF::DdtfHelpers
        .send(:get_proton_id_from_runtime_config, rt)
      expect(result).to eq('quux')
    end
  end
end
