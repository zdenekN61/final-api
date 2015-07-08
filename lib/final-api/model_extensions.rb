require 'final-api/ddtf'

class Request < Travis::Model
  def to_hash
    self.serializable_hash.slice(
      "id",
      "jid",
      "state",

      "head_commit",
      "base_commit",
      "commit_id",

      #"payload",
      "config",
      "event_type",
      "message",

      "owner_id",
      "owner_type",

      "repository_id",
      "result",
      "source",

      "created_at",
      "started_at",
      "finished_at",
      "updated_at"
    )

  end
end

class Build < Travis::Model
  include FinalAPI::DDTF

  def to_hash
    self.serializable_hash.slice(
      "id",
      "state",
      "repository_id",
      "commit_id",
      "request_id",
      "config",

      "branch",
      "number",

      "created_at",
      "received_at",
      "started_at",
      "finished_at",
      "updated_at",
      "canceled_at",
      "duration" ,

      "owner_id" ,
      "owner_type",

      "event_type" ,
      "previous_state",
      "pull_request_title",
      "pull_request_number",

      "cached_matrix_ids",
    )

  end
end

class Job < Travis::Model
  def to_hash
    self.serializable_hash.slice(
      "id",
      "state",
      "number",

      "repository_id",
      "commit_id",
      "source_id",
      "source_type",
      "queue",
      "type",
      "config",
      "worker",

      "created_at",
      "received_at",
      "queued_at",
      "started_at",
      "finished_at",
      "updated_at",
      "canceled_at",

      "owner_id",
      "owner_type",

      "tags",
      "allow_failure",
      "result"
    )

  end
end


