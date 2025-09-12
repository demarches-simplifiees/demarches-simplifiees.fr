# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :application_base_url
  attribute :application_name
  attribute :browser
  attribute :contact_email
  attribute :host
  attribute :no_reply_email
  attribute :request_id
  attribute :user
  attribute :procedure_columns
  attribute :db_queries_count
end
