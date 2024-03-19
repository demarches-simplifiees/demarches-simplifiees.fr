class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id, :browser,
    :host, :application_name, :contact_email,
    :application_base_url
end
