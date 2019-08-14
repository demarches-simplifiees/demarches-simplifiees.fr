namespace :after_party do
  desc 'Deployment task: populate_user_administrateur_ids'
  task populate_user_administrateur_ids: :environment do
    Administrateur.find_each do |administrateur|
      User.where(email: administrateur.email).update(administrateur_id: administrateur.id)
    end

    AfterParty::TaskRecord.create version: '20190809074534'
  end
end
