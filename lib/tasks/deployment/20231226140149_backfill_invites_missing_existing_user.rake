# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_invites_missing_existing_user'
  task backfill_invites_missing_existing_user: :environment do
    puts "Running deploy task 'backfill_invites_missing_existing_user'"

    # Put your task implementation HERE.
    Invite.where.missing(:user).in_batches do |invites_with_missing_user|
      linkable_users_and_invite = User.where(email: invites_with_missing_user.pluck(:email))
      linkable_users_and_invite.each do |linkable_user_and_invite|
        begin
          linkable_user_and_invite.after_confirmation # calls link_invites!
        rescue err
          Sentry.capture_exception(err)
        end
      end
    end
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
