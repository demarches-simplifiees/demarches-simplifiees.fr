namespace :after_party do
  desc 'Deployment task: fix_email_templates_subjects'
  task fix_email_templates_subjects: :environment do
    puts "Running deploy task 'fix_email_templates_subjects'"

    klasses = [
      Mails::ClosedMail,
      Mails::InitiatedMail,
      Mails::ReceivedMail,
      Mails::RefusedMail,
      Mails::WithoutContinuationMail
    ]

    klasses.each do |klass|
      klass
        .where("subject LIKE '%--libellé procédure--%'")
        .each do |instance|

        instance.update(subject: instance.subject.gsub("--libellé procédure--", "--libellé démarche--"))
        rake_puts "Subject mis-à-jour pour #{klass.to_s}##{instance.id}"
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20181219122438'
  end # task :fix_email_templates_subjects
end # namespace :after_party
