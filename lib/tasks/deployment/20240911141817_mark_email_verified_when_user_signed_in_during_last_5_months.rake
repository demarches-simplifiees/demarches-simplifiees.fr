# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: mark_email_verified_when_user_signed_in_during_last_5_months'
  task mark_email_verified_when_user_signed_in_during_last_5_months: :environment do
    users_signed_in_during_last_5_months = User.where(email_verified_at: nil, created_at: 5.months.ago.., sign_in_count: 1..)

    affected_users_count = users_signed_in_during_last_5_months.count

    puts "Processing #{affected_users_count} users signed in during the last 5 months and not verified"

    users_signed_in_during_last_5_months.update_all(email_verified_at: Time.zone.now)
    puts "Done"

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
