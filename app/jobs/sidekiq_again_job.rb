# frozen_string_literal: true

class SidekiqAgainJob < ApplicationJob
  self.queue_adapter = :sidekiq
  queue_as :default

  def perform(user, with_exception: false)
    if with_exception
      raise 'Nop'
    end
    Sentry.capture_message('this is a message from sidekiq')
    UserMailer.new_account_warning(user).deliver_now
  end
end
