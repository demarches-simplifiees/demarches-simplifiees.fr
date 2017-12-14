namespace :'2017_12_04_translate_dossier_state_to_french' do
  task brouillon: :environment do
    Dossier.unscoped.where(state: 'draft').update_all(state: 'brouillon')
  end

  task en_construction: :environment do
    Dossier.unscoped.where(state: 'initiated').update_all(state: 'en_construction')
  end

  task en_instruction: :environment do
    Dossier.unscoped.where(state: 'received').update_all(state: 'en_instruction')
  end
end
