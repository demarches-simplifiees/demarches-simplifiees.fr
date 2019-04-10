namespace :after_party do
  desc 'Deployment task: migrate_mail_body_to_actiontext'
  task migrate_mail_body_to_actiontext: :environment do
    puts "Running deploy task 'migrate_mail_body_to_actiontext'"

    # Put your task implementation HERE.

    [Mails::InitiatedMail, Mails::ReceivedMail, Mails::ClosedMail, Mails::WithoutContinuationMail, Mails::RefusedMail].each do |mt_class|
      progress = ProgressReport.new(mt_class.all.count)

      mt_class.all.each do |mt|
        if mt.body.present?
          mt.rich_body = mt.body
          mt.save
        end
        progress.inc
      end

      progress.finish
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190410131747'
  end # task :migrate_mail_body_to_actiontext
end # namespace :after_party
