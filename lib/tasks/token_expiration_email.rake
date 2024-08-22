# frozen_string_literal: true

require Rails.root.join("lib", "tasks", "task_helper")

namespace :token_expiration_email do
  task send_warning: :environment do
    admin_tokens = APIToken
      .includes(:administrateur)
      .where(version: [1, 2])
      .to_a
      .group_by(&:administrateur)

    admin_tokens.each do |admin, tokens|
      AdministrateurMailer.api_token_expiration(admin.user, tokens).deliver_later
    end
  end
end
