# frozen_string_literal: true

module BalancedDeliveryConcern
  extend ActiveSupport::Concern

  included do
    before_action :add_delivery_method, if: :forced_delivery_provider?

    def critical_email?
      self.class.critical_email?(action_name)
    end

    def bypass_unverified_mail_protection!
      headers[BalancerDeliveryMethod::BYPASS_UNVERIFIED_MAIL_PROTECTION] = true
    end

    private

    def forced_delivery_provider?
      SafeMailer.forced_delivery_method.present? && critical_email?
    end

    def add_delivery_method
      headers[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER] = SafeMailer.forced_delivery_method
    end
  end
end
