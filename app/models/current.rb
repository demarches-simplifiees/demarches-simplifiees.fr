class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id
end
