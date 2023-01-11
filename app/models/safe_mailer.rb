# == Schema Information
#
# Table name: safe_mailers
#
#  id                     :bigint           not null, primary key
#  forced_delivery_method :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class SafeMailer < ApplicationRecord
  before_create do
    raise if SafeMailer.count == 1
  end

  enum forced_delivery_method: Rails.application.config.action_mailer&.balancer_settings&.keys&.map(&:to_s) || []

  def self.forced_delivery_method
    first&.forced_delivery_method
  end
end
