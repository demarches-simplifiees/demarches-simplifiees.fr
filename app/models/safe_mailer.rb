# frozen_string_literal: true

class SafeMailer < ApplicationRecord
  before_create do
    raise if SafeMailer.count == 1
  end

  enum forced_delivery_method: (Rails.application.config.action_mailer&.balancer_settings&.keys || []).to_h { |k| [k.to_sym, k.to_s] }

  def self.forced_delivery_method
    first&.forced_delivery_method
  end
end
