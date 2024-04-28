# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: block_dubious_email'
  task block_dubious_email: :environment do
    User
      .where.associated(:instructeur)
      .where(created_at: ..3.months.ago)
      .where(last_sign_in_at: nil)
      .update_all(email_verified_at: nil)

    User
      .where.associated(:expert)
      .where(created_at: ..3.months.ago)
      .where(last_sign_in_at: nil)
      .update_all(email_verified_at: nil)

    # rubocop:disable DS/Unscoped
    User
      .unscoped
      .where.missing(:instructeur, :expert)
      .where(confirmed_at: nil)
      .update_all(email_verified_at: nil)
    # rubocop:enable DS/Unscoped

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
