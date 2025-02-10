# frozen_string_literal: true

module PriorityDeliveryConcern
  extend ActiveSupport::Concern
  included do
    self.delivery_job = PriorizedMailDeliveryJob

    before_action :set_forced_delivery_method, if: :should_force_delivery?

    def self.critical_email?(action_name)
      raise NotImplementedError
    end

    def critical_email?
      self.class.critical_email?(action_name)
    end

    def bypass_unverified_mail_protection!
      headers[BalancerDeliveryMethod::BYPASS_UNVERIFIED_MAIL_PROTECTION] = true
    end

    private

    def should_force_delivery?
      SafeMailer.forced_delivery_method.present? && critical_email?
    end

    def set_forced_delivery_method
      headers[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER] = SafeMailer.forced_delivery_method
    end
  end
end
