namespace :'2017_07_18_clean_followed_dossiers' do
  task clean: :environment do
    Follow.where(gestionnaire_id: nil).destroy_all
    Follow.where(dossier_id: nil).destroy_all

    duplicate_follows = Follow.group('gestionnaire_id', 'dossier_id').count.select { |_gestionnaire_id_dossier_id, count| count > 1 }.keys

    duplicate_ids = duplicate_follows.map { |gestionnaire_id, dossier_id| Follow.where(gestionnaire_id: gestionnaire_id, dossier_id: dossier_id).pluck(:id) }

    duplicate_ids.each do |ids|
      ids.pop
      Follow.where(id: ids).destroy_all
    end
  end
end
