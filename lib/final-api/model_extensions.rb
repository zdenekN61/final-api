require 'final-api/ddtf'

class Build
  include FinalAPI::DDTF

  def parts_groups
    matrix.group_by do |t|
      t.config_vars_hash['PART'] || t.config_vars_hash['Part']
    end
  end

  # set mandatory properties
  # this is temporary solution for invalid data in DB
  # ...and just for development phase
  def sanitize
    self.repository ||= Repository.first
    self.owner ||= User.first
    self.request ||= Request.new
    self
  end
end

class Job
  include FinalAPI::DDTF

  def ddtf_test_resutls
    test_results_path = "/var/lib/final-ci/test-results/#{id}.json"
    raw_test_results = MultiJson.load(File.read(test_results_path)) rescue []
  end

  def ddtf_machine
    config_vars_hash['MACHINE'] || config_vars_hash['Machine'] || 'NoMachine'
  end

end

=begin
class MachinesResults
  attr_reader :machine, :result, :uuid
end

class AggregatedTestStepResult
  attr_reader :description, :machines_results

  def add_step(uuid:, machine:, description:, result:)
  end
end

class TestCaseResult
  attr_reader :description, :result

  def test_cases
  end


  def parse_step(opts)
    test_case = test_cases[class_position] || {}
    fail 'Description not mach!' if !test_case.empty? and opts[:class_name] != test_case[:description]

    test_case[:description] = opts[:class_name]
    test_case[:testSteps] ||= []

    test_step = test_case[:testSteps][opts[:position]] || {}
    fail 'Description not mach!' if !test_case.empty? and opts[:name] != test_case[:name]
    test_step[:machines] ||= {}
    test_step[:machines][machine] = { result: opts[:result] }
  end

end
=end


