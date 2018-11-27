namespace :after_party do
  desc 'Deployment task: add_stable_id_to_types_de_champ'
  task add_stable_id_to_types_de_champ: :environment do
    types_de_champ = TypeDeChamp.where(stable_id: nil)
    bar = RakeProgressbar.new(types_de_champ.count)

    types_de_champ.find_each do |type_de_champ|
      type_de_champ.update_column(:stable_id, type_de_champ.id)
      bar.inc
    end
    bar.finished

    AfterParty::TaskRecord.create version: '20181123181252'
  end
end
