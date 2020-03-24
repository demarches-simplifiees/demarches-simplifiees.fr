namespace :after_party do
  desc 'Deployment task: desactivate_instructeurs_no_longer_present'
  task moved_instructeurs: :environment do
    puts "Running deploy task 'moved_instructeurs'"

    # some instructeurs has moved and their address is no longer valid.
    # ==> unaffect them from any procedures

    Instructeur.by_email('lydia.laugeon@artisanat.gov.pf')&.groupe_instructeurs&.destroy_all
    Instructeur.by_email('aloma.maihota@transport.gov.pf')&.groupe_instructeurs&.destroy_all
    Instructeur.by_email('frank.giandolini@equipement.gov.pf')&.groupe_instructeurs&.destroy_all
    Instructeur.by_email('eve.laine@artisanat.gov.pf')&.groupe_instructeurs&.destroy_all
    Instructeur.by_email('vaehei.teriiteporouarai@equipement.gov.pf')&.groupe_instructeurs&.destroy_all

    AfterParty::TaskRecord.create version: '20200324012659'
  end # task :moved_instructeurs
end # namespace :after_party
