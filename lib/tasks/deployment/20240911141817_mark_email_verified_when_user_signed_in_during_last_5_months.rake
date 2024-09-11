# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: mark_email_verified_when_user_signed_in_during_last_5_months'
  task mark_email_verified_when_user_signed_in_during_last_5_months: :environment do
    affected_users_count = User.where(email_verified_at: nil, sign_in_count: 1..).count

    puts "Processing #{affected_users_count} users signed in during the last 5 months and not verified"

    User.where(email_verified_at: nil, sign_in_count: 1..).update_all(email_verified_at: Time.zone.now)
    puts "Done"

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
