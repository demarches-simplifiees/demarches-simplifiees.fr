# frozen_string_literal: true

class SafeMailer < ApplicationRecord
  before_create do
    raise if SafeMailer.count == 1
  end

  if Rails.application.config.action_mailer.balancer_settings.present?
    enum :forced_delivery_method, (Rails.application.config.action_mailer.balancer_settings.keys || []).to_h { |k| [k.to_sym, k.to_s] }
  end

  def self.forced_delivery_method
    first&.forced_delivery_method
  end
end
