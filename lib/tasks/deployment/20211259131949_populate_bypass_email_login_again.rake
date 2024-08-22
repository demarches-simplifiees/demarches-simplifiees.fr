# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: populate_bypass_email_login'
  task populate_bypass_email_login_again: :environment do
    user_ids = Flipper::Adapters::ActiveRecord::Gate
      .where(feature_key: 'instructeur_bypass_email_login_token')
      .pluck(:value)
      .filter { |s| s.start_with?('User:') }
      .map { |s| s.gsub('User:', '') }
      .map(&:to_i)

    Instructeur
      .where(user: { id: user_ids })
      .update_all(bypass_email_login_token: true)

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
