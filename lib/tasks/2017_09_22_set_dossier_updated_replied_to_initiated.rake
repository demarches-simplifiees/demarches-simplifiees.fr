namespace :'2017_09_22_set_dossier_updated_replied_to_initiated' do
  task set: :environment do
    Dossier.with_hidden.where(state: [:updated, :replied]).update_all(state: :initiated)
  end
end
