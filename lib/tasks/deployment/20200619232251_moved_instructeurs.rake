namespace :after_party do
  desc 'Deployment task: administrative_mails_no_longer_valid'
  task moved_instructeurs: :environment do
    puts "Running deploy task 'moved_instructeurs'"

    # some instructeurs has moved and their address is no longer valid.
    # ==> unaffect them from any procedures

    Instructeur.by_email('stephanie.chalons@dgrh.gov.pf')&.groupe_instructeurs&.destroy_all
    Instructeur.by_email('chantal.delort@dgrh.gov.pf')&.groupe_instructeurs&.destroy_all
    Instructeur.by_email('kahaina.ahini@jeunesse.gov.pf')&.groupe_instructeurs&.destroy_all
    Instructeur.by_email('andy.teihotaata@dgrh.gov.pf')&.groupe_instructeurs&.destroy_all

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20200619232251'
  end # task :moved_instructeurs
end # namespace :after_party
