module BalancedDeliveryConcern
  extend ActiveSupport::Concern

  included do
    before_action :add_delivery_method, if: :forced_delivery?

    private

    def forced_delivery_for_action?
      false
    end

    def forced_delivery?
      SafeMailer.forced_delivery_method.present? && forced_delivery_for_action?
    end

    def add_delivery_method
      headers[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER] = SafeMailer.forced_delivery_method
    end
  end
end
