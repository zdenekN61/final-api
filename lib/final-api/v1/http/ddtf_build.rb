require 'active_support/core_ext/string/inflections'
require 'test_aggregation'

module FinalAPI
  module V1
    module Http
      class DDTF_Build

        include ::Travis::Api::Formats

        attr_reader :build, :commit, :request

        BUILD_STATE2API_V1STATUS = {
          'created' => 'Configured',
          'received' => 'Pending',
          'started' => 'Running',
          'passed' => 'Finished',
          'failed' => 'Finished',
          'canceled' => 'Stopped',
          'errored' => 'Aborted',
          '' => 'Unbeknownst'
        }

        def initialize(build, options = {})
          @build = build
          @commit = build.commit
          @request = build.request
        end

        #statuses are mapped in app/common/filters/status-class-filter.js on AtomUI side
        def test_data
          config = build.config

          {
            'id' => build.id,
            'buildId' => build.id,
            'ddtfUuid' => config[:ddtf_uuid] ||
              config[:ddtf_uid] ||
              config[:ddtfUuid],
            'name' => build.name,
            'description' => config[:description],
            'branch' => config[:branch],
            'build' => build.build_info,

            'status' => BUILD_STATE2API_V1STATUS[build.state.to_s.downcase],
            'strategy': config[:strategy],
            'email': config[:email],

            'started': build.created_at,
            'enqueued': build.started_at,
            'startedBy': build.owner.try(:name).to_s,

            'stopped': build.canceled_at,
            'stoppedBy': build.stopped_by.try(:name), # TODO

            'isTsd': true,
            'checkpoints':    checkpoints,
            'buildSignal':    config[:build_signal] || false,
            'scenarioScript': config[:scenario_script] || false,
            'executionLogs':  execution_logs,

            'stashTSD':       config[:stashTsd],
            'runtimeConfig':  ddtf_runtimeConfig,
            'product': product,

            'parts': parts_status,
            'tags': [],

            'result': build.state,

            #progress bar:
            'results': ddtf_results_distribution
          }
        end

        def retest_data
          config = build.config
          {
            'email' => config[:email],
            'packageSource' => config[:packageFrom],
            'package' => config[:branch],
            'strategy' => config[:strategy],
            'build' => build.build_info,
            'description' => config[:description],
            'checkpoints' => checkpoints,
            'runtimeConfigFields' => ddtf_runtimeConfig,
            'tsd' => build.config[:tsdContent]
          }
        end

        def parts_data
          ddtf_test_aggregation_result.as_json
        end

        def atom_response
          {
            id: build.id.to_s, # BAMBOO expects string in v1 API
            name: build.name,
            build: build.build_info,
            result: 'NotSet',
            results:[
            {
              Type: 'NotSet',
              Value: 1.0
            }],
            enqueued: Time.now
          }
        end

        def execution_logs
          build.execution_logs.each_with_object([]) do |execution_log, result|
            result << {
              position: execution_log.position,
              timestamp: execution_log.timestamp.iso8601,
              message:  execution_log.message
            }
          end
        end

        private

        def product
          tsd = build.config[:tsdContent]
          tsd[:product] if tsd
        end

        # returns hash of results of all test
        def ddtf_results_distribution
          res = ddtf_test_aggregation_result.new_states_results_hash.reject do |(step_result, count)|
            step_result == 'NotPerformed' || step_result == 'Skipped'
          end

          total = res.values.reduce(:+)

          res.each_with_object([]) do |(step_result, count), result|
            result << { type: step_result, value: count.to_f / total }
          end
        end

        def ddtf_runtimeConfig
          build.config[:runtimeConfig] || []
        end

        def checkpoints
          build.config[:checkpoint] || false
        end

        def parts_status
          build.parts_groups.map do |part_name, jobs|
            {
              name: part_name,
              result: ddtf_test_aggregation_result.part_result(part_name)
            }
          end
        end

        def ddtf_test_aggregation_result
          return @ddtf_test_aggregation_result if (
            defined?(@ddtf_test_aggregation_result) &&
            @ddtf_test_aggregation_result
          )

          @ddtf_test_aggregation_result ||= TestAggregation::BuildResults.new(
            build,
            ->(job) { job.ddtf_part }, # get part from job config
            ->(job) { job.ddtf_machine }, # get machine from job config
            ->(step_result) { # mapping of new state to old state
              begin
                step_result[:data]['status'].split('_').collect(&:capitalize).join
              rescue
                return 'NotSet' if step_result[:result] == 'created'
                return 'NotTested' if step_result[:result] == 'blocked'
                step_result[:result].capitalize
              end
            }
          )
          build.matrix.each do |job|
            StepResult.where(job_id: job.id).order('id desc').each do |sr|
              @ddtf_test_aggregation_result.parse(sr.data)
            end
          end
          @ddtf_test_aggregation_result
        end
      end
    end
  end
end
