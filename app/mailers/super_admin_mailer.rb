# frozen_string_literal: true

class SuperAdminMailer < ApplicationMailer
  def self.critical_email?(action_name)
    false
  end
end
