require 'final-api/ddtf'

class Build
  include FinalAPI::DDTF

  def parts_groups
    matrix.group_by { |t| t.config_vars_hash['PART'] }
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
    test_results_path = "../travis-test-results/results/#{id}.json"
    raw_test_results = MultiJson.load(File.read(test_results_path)) rescue []
  end

end


