require 'final-api/ddtf'

class Build
  include FinalAPI::DDTF

  # Represents metadat for query language used by frondend
  # *key* are query keywords
  # *values* are columns in DB (use Postgres JSON ->> operator)
  SEARCH_TOKENS_DEF = {
    ['id']                => 'id',
    ['nam', 'name']       => 'config ->> \'name\'',
    ['enq', 'enqueuedBy'] => 'config ->> \'enqueuedBy\'',
    ['sta', 'startedBy']  => 'config ->> \'startedBy\'',
    ['sto', 'stoppedBy']  => 'config ->> \'stoppedBy\'',
    ['sts', 'stat', 'status', 'state'] => 'state',
    ['que', 'queueName']  => 'config ->> \'queueName\'',
    ['bui', 'build']      => 'config ->> \'build\'',
    ['protonid', 'protonId'] => 'config ->> \'protonId\''
  }

  def self.ddtf_search(query)
    res = scoped
    return res if query.blank?
    res_query = query.dup
    SEARCH_TOKENS_DEF.each_pair do |keys, column|
      if res_query.sub!(/(?:#{keys.join('|')})\s*([:=])\s*("(?:[^"]*?")|[\w\d_]+)/, '')
        op = $1
        term = $2.gsub(/\A"(.*)"\z/, '\1')
        res = res.ddtf_search_column(column, op, term)
      end
    end
    # when no keyword found search in `name` field by "contaions" operator
    if res_query == query
      res = res.ddtf_search_column('config ->> \'name\'', ':', query)
    end
    res
  end

  def self.ddtf_search_column(column, operator, term)
    case operator
    when '='
      # makes search quite slow (and without index)
      # but users are unaware of types, and could write: WHERE id = 'string'
      # which leads to error:
      #   PG::InvalidTextRepresentation: ERROR:  invalid input syntax for integer
      column = "(#{column})::text"
    when ':'
      operator = 'ILIKE'
      term = "%#{term}%"
      column = "(#{column})::text"
    else
      fail "Unknown operator: #{operator.inspect}"
    end
    where([column, operator, '?'].join(' '), term)
  end


  def parts_groups
    matrix.group_by do |t|
      t.config_vars_hash['PART'] || t.config_vars_hash['Part']
    end
  end

  # set mandatory properties
  # this is temporary solution for invalid data in DB
  # ...and just for development phase
  def sanitize
    self.repository ||= Repository.new
    self.owner ||= User.new
    self.request ||= Request.new
    self
  end

  private

end

class Job
  include FinalAPI::DDTF

  def ddtf_test_resutls
    test_results_path = File.join(Travis.config.test_results.results_path, "#{id}.json")
    raw_test_results = MultiJson.load(File.read(test_results_path)) rescue []
  end

  def ddtf_machine
    config_vars_hash['MACHINE'] || config_vars_hash['Machine'] || 'NoMachineDefined'
  end

  def ddtf_part
    config_vars_hash['PART'] || config_vars_hash['Part'] || 'NoPartDefined'
  end

end

