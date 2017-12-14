namespace :'2017_12_04_translate_dossier_state_to_french' do
  task en_construction: :environment do
    Dossier.unscoped.where(state: 'initiated').update_all(state: 'en_construction')
  end
end
