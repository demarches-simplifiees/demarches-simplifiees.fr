namespace :after_party do
  desc 'Deployment task: backfill_daily_email_notification_columns'
  task backfill_daily_email_notification_columns: :environment do
    puts "Running deploy task 'backfill_daily_email_notification_columns'"
    AssignTo.find_each do |assign_to|
      columns_to_update = {}
      if assign_to.email_notifications_enabled != assign_to.daily_email_notifications_enabled
        columns_to_update[:daily_email_notifications_enabled] = assign_to.email_notifications_enabled
      end
      assign_to.update_columns(columns_to_update) unless columns_to_update.empty?
    end
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20200220142710'
  end # task :backfill_daily_email_notification_columns
end # namespace :after_party
