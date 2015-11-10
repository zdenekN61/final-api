require 'active_support/core_ext/string/inflections'

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
          config_vars = build.config_vars_hash
          config = build.config

          {
            'id' => build.id,
            'name' => config[:name],
            'description' => config[:description],
            'branch' => config[:branch],
            'build' => config[:build],
            'queueName' => config[:queueName],

            #configured, pending, running, stopping, finished, stoped, aborted
            'status' => build.state, #TODO: convert to state?
            'strategy': config[:strategy],
            'email': config[:email],

            'started': build.created_at.to_s,  #TODO remove to_s
            'enqueued': build.started_at.to_s, #TODO remove to_s
            'startedBy': build.owner.try(:name).to_s,
            'enqueuedBy': build.owner.try(:name).to_s,    #TODO will be removed

            'stopped': build.state == 'cancelled',   # TODO: what does it mean status cancelled?
            'stoppedBy': nil, # TODO

            'isTsd': true,
            'checkpoints':    config[:checkpoints],
            'debugging':      config[:debbuging],
            'buildSignal':    config[:build_signal],
            'scenarioScript': config[:scenario_script],
            'packageSource':  config[:package_source],
            'executionLogs':  request.try(:message).to_s,
            'stashTSD':       config[:tsd_content],
            'runtimeConfig':  ddtf_runtimeConfig,

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
                { os: job.ddtf_machine, result: job.state, id: job.id }
              end,
              testCases: ddtf_test_cases(jobs)
            }
          end
        end


        private

        def ddtf_runtimeConfig
          runtimeConfig = build.config[:runtimeConfig] || {}
          runtimeConfig.each_with_object([]) do |(key, value), obj|
            obj << { 'definition' => key, 'value' => value }
          end
        end

        def parts_status
          build.parts_groups.map do |part_name, jobs|
            {
              name: part_name,
              result: sum_states(jobs.map(&:state))
            }
          end
        end

        def ddtf_test_cases(jobs)
          result = []
          jobs.each do |job|
            job_result = job.ddtf_test_resutls.map do |test_case|
              ddtf_convert_case(job, test_case)
            end

            result = ddtf_add_result(result, job_result)
          end
          result
        end

        # helper method
        # merge result and job_result together
        # it is array of test cases. Each TestCase contains array of test steps.
        def ddtf_add_result(result, job_result)
          0.upto([result.size, job_result.size].max - 1) do |idx|
            add = job_result[idx] || {}
            res = result[idx] || add

            result[idx] = res.deep_merge(add)
            test_steps_res = res[:testSteps] || []
            test_steps_add = add[:testSteps] || []
            0.upto([test_steps_res.size, test_steps_add.size].max - 1) do |t_idx|
              result[idx][:testSteps][t_idx] = (test_steps_res[t_idx] || {}).deep_merge(test_steps_add[t_idx] || {})
            end
          end
          result
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
          return { description: 'unknown test case', result: 'created' } unless test_case

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
                job.ddtf_machine => { result: 'created' }
              }
            }
          end

          resutl = nil
          result = step['data']['status'] if step['data']
          result ||= step['result']

          result = result.camelize

          {
            id: step['uuid'],
            description: step['name'],
            machines: {
              job.ddtf_machine => { result: result }
            }
          }
        end

        def test_steps_results(test_steps)
          Array.wrap(test_steps).map { |step| step['result'] }
        end

      end
    end
  end
end
