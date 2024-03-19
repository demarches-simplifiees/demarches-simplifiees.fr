class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id, :browser, :host, :application_name
end
