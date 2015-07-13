module FinalAPI
  module V1
    module Http
      class Request
        include ::Travis::Api::Formats

        attr_reader :request, :options

        def initialize(request, options = {})
          @request = request
          @options = options
        end

        def data
          res = {
            'id'            => request.id,
            'state'         => request.state.to_s,       #added
            'build_ids'     => request.build_ids,        #added
            'jid'           => request.jid,
            'commit_id'     => request.commit_id,
            'repository_id' => request.repository_id,
            'created_at'    => format_date(request.created_at),
            'owner_id'      => request.owner_id,
            'owner_type'    => request.owner_type,
            'event_type'    => request.event_type,
            'base_commit'   => request.base_commit,
            'head_commit'   => request.head_commit,
            'result'        => request.result,
            'message'       => request.message,
            'pull_request'  => request.pull_request?,
            'pull_request_number' => request.pull_request_number,
            'pull_request_title' => request.pull_request_title,
            'branch'        => request.branch_name,
            'tag'           => request.tag_name
          }

          res['builds'] = Builds.new(request.builds).data

          res
        end
      end
    end
  end
end
