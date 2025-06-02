# frozen_string_literal: true

module PriorityDeliveryConcern
  extend ActiveSupport::Concern
  included do
    self.delivery_job = PriorizedMailDeliveryJob

    def self.critical_email?(action_name)
      raise NotImplementedError
    end
  end
end
