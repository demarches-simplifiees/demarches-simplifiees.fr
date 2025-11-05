# frozen_string_literal: true

require "administrate/base_dashboard"

class EmailEventDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    to: Field::String,
    subject: Field::String,
    method: Field::Enum,
    status: Field::Enum,
    processed_at: Field::DateTime.with_options(format: "%F %T"),
  }
  COLLECTION_ATTRIBUTES = [:id, :to, :subject, :method, :status, :processed_at].freeze
  SHOW_PAGE_ATTRIBUTES = [:id, :to, :subject, :method, :status, :processed_at].freeze

  METHODS_FILTERS =
    ActionMailer::Base.delivery_methods.keys.index_with do |method|
      -> (resources) { resources.where(method: method) }
    end

  COLLECTION_FILTERS = {
    dispatched: -> (resources) { resources.dispatched },
    dispatch_error: -> (resources) { resources.dispatch_error },
  }.merge(METHODS_FILTERS).freeze
end
