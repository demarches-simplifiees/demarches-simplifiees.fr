namespace :after_party do
  desc 'Deployment task: fix_bad_invitation_targeted_user_link'
  task fix_bad_invitation_targeted_user_link: :environment do
    puts "Running deploy task 'fix_bad_invitation_targeted_user_link'"

    # Put your task implementation HERE.

    invalid_invites = Invite.where('invites.created_at > ?', 1.month.ago)
      .joins(:targeted_user_link)
      .where(targeted_user_link: { target_model_type: 'Avis' })
    progress = ProgressReport.new(invalid_invites.count)
    invalid_invites.find_each do |invite|
      invite.send_notification
      progress.inc
    end
    progress.finish
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
