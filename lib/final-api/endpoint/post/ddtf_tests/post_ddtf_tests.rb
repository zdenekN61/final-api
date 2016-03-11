require 'final-api/ext/hash'

module FinalAPI::Endpoint
  module DDTF
    class PostDdtfTests
      class << self
        public
        def get_new_build_params(test_data, tsd)
          {
            user_id: User.where(name: 'FIN').first.id,
            repository_id: Repository.where(name: 'test-repo').first.id,
            config:
            {
              language: 'tsd',
              git:
              {
                no_clone: true
              },
              name: tsd['name'],
              description: test_data.get_ikey('Description'),
              branch: test_data.get_ikey('Package'),
              build: test_data.get_ikey('Build'),
              strategy: test_data.get_ikey('Strategy') || tsd['defaultStrategy'],
              email: test_data.get_ikey('Email'),
              checkpoint: test_data.get_ikey('Checkpoints'),
              scenarioScript: test_data.get_ikey('ScenarioScript'),
              stashTsd: test_data.get_ikey('StashTSD'),
              tsdContent: test_data.get_ikey('File'),
              runtimeConfig: test_data.get_ikey('RuntimeConfigFields'),
              ddtfUuid: test_data.get_ikey('Id')
            }
          }
        end
      end
    end
  end
end
