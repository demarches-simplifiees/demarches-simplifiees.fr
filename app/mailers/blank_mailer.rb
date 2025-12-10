# frozen_string_literal: true

class BlankMailer < ApplicationMailer
  layout 'mailers/layout'

  def send_template(to:, subject:, title:, body:)
    @title = title
    @body = body

    mail(to:, subject:)
  end

  def self.critical_email?(action_name) = false
end
