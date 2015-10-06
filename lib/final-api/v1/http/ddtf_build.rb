module FinalAPI
  module V1
    module Http
      class DDTF_Build

        include ::Travis::Api::Formats

        attr_reader :build, :commit, :request

        def initialize(build, options = {})
          @build = build
          @commit = build.commit
          @request = build.request
        end

        #statuses are mapped in app/common/filters/status-class-filter.js on AtomUI side
        def test_data
          {
            'id' => build.id,
            'name' => 'TODO: `name` needs to be persisted to DB as column', #config_vars_hash['NAME']
            'description' => 'TODO: `description` needs to be persisted to DB as column', #config_vars_hash['DESCRIPTION']
            'branch' => 'TODO: `branch` rename as package_provider - needs to be persisted to DB as column',
            'build' => 'TODO: `build` needs to be persisted to DB as column',
            'queueName' => 'TODO: use regular tagging library?',

            #configured, pending, running, stopping, finished, stoped, aborted
            'status' => build.state, #TODO: convert to state?
            'strategy': 'TODO: `strategy` needs to be persisted to DB as column',
            'email': 'TODO: `email` needs to be persisted to DB as column', #owner.email

            'started': build.created_at.to_s,  #TODO remove to_s
            'enqueued': build.started_at.to_s, #TODO remove to_s
            'startedBy': 'TODO', #build.owner.name,
            'enqueuedBy': 'TODO', #build.owner.name,    #TODO will be removed

            'stopped': build.state == 'cancelled',   # TODO: what does it mean status cancelled?
            'stoppedBy': nil, # TODO

            'isTsd': true,
            'checkpoints':    build.config_vars_hash['CHECKPOINTS'],
            'debugging':      build.config_vars_hash['DEBBUGING'],
            'buildSignal':    build.config_vars_hash['BUILD_SIGNAL'],
            'scenarioScript': build.config_vars_hash['SCENARIO_SCRIPT'],
            'packageSource':  build.config_vars_hash['PACKAGE_SOURCE'],
            'executionLogs': request ? request.message : '',
            'stashTSD': 'TODO: `build` needs to be persisted to DB as column',
            'runtimeConfig': build.config['runtimeConfig'],

            'parts': parts_status,
            'tags': [],

            'result': build.state,

            #progress bar:
            'results': [
              {
                type: 'NotSet', #Passed, Failed, knownBug, notTested, NotSet
                value: 1
              }
            ]
          }
        end

        def parts_data
          build.parts_groups.map do |part_name, jobs|
            {
              name: part_name,
              result: sum_states(jobs.map(&:state)),
              machines: jobs.map do |job|
                { os: job.config_vars_hash['MACHINE'], result: job.state, id: job.id }
              end,
              testCases: ddtf_test_cases(jobs)
            }
          end
        end


        private

        def parts_status
          build.parts_groups.map do |part_name, jobs|
            {
              name: part_name,
              result: sum_states(jobs.map(&:state))
            }
          end
        end

        def ddtf_test_cases(jobs)
          job = jobs.first
          job.ddtf_test_resutls.map do |test_case|
            ddtf_convert_case(job, test_case)
          end
        end

        def sum_states(states)
          return 'failed' if states.include?('failed')
          return 'errored' if states.include?('errored')
          return 'cancelled' if states.include?('cancelled')

          return 'passed' if states.all? { |t| t == 'passed' or t == 'Passed' }

          return 'started' if states.include?('started')
          return 'received' if states.include?('received')
          return 'received' if states.include?('received')
          return 'created' if states.include?('created')

          raise "Unknown result state for #{states.inspect}"
        end

        def ddtf_convert_case(job, test_case)
          return { description: 'unknown test case', result: 'NotSet' } unless test_case

          {
            description: test_case['classname'],
            result: 'Failed', #sum_states(test_steps_results(test_case['steps'])),
            testSteps: Array.wrap(test_case['steps']).map { |step| ddtf_convert_step(job, step) }
          }
        end

        def ddtf_convert_step(job,step)
          unless step
            return {
              description: 'unknown step',
              machines: {
                ddtf_machine(job) => { result: 'NotSet' }
              }
            }
          end

          {
            id: step['uuid'],
            description: step['name'],
            machines: {
              ddtf_machine(job) => { result: step['result'] }
            }
          }
        end


        def ddtf_machine(job)
          job.config_vars_hash['MACHINE'] || 'Unknown machine'
        end

        def test_steps_results(test_steps)
          Array.wrap(test_steps).map { |step| step['result'] }
        end

      end
    end
  end
end
