require 'travis/config'
require 'travis/support'

module FinalAPI
  class Config < Travis::Config
    define database:      { adapter: 'postgresql', database: "travis_#{Travis.env}", encoding: 'unicode', min_messages: 'warning' },
            encryption:    Travis.env == 'development' || Travis.env == 'test' ? { key: 'secret' * 10 } : {}


    def env
      Travis.env
    end

  end
end
