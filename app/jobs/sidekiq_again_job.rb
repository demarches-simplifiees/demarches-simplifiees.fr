class SidekiqAgainJob < ApplicationJob
  self.queue_adapter = :sidekiq
  queue_as :default

  def perform(user)
    UserMailer.new_account_warning(user).deliver_now
  end
end
