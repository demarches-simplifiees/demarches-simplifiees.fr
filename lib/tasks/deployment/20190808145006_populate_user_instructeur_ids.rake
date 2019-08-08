namespace :after_party do
  desc 'Deployment task: populate_user_instructeur_ids'
  task populate_user_instructeur_ids: :environment do
    Instructeur.find_each do |instructeur|
      User.where(email: instructeur.email).update(instructeur_id: instructeur.id)
    end

    AfterParty::TaskRecord.create version: '20190808145006'
  end
end
