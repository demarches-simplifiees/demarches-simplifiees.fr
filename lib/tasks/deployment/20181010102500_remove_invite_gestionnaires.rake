namespace :after_party do
  desc 'Deployment task: remove_invite_gestionnaires'
  task remove_invite_gestionnaires: :environment do
    InviteGestionnaire.destroy_all

    # Update task as completed. If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20181010102500'
  end
end
