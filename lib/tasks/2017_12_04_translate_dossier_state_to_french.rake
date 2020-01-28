namespace :'2017_12_04_translate_dossier_state_to_french' do
  task brouillon: :environment do
    Dossier.with_hidden.where(state: 'draft').update_all(state: 'brouillon')
  end

  task en_construction: :environment do
    Dossier.with_hidden.where(state: 'initiated').update_all(state: 'en_construction')
  end

  task en_instruction: :environment do
    Dossier.with_hidden.where(state: 'received').update_all(state: 'en_instruction')
  end

  task accepte: :environment do
    Dossier.with_hidden.where(state: 'closed').update_all(state: 'accepte')
  end

  task refuse: :environment do
    Dossier.with_hidden.where(state: 'refused').update_all(state: 'refuse')
  end

  task sans_suite: :environment do
    Dossier.with_hidden.where(state: 'without_continuation').update_all(state: 'sans_suite')
  end

  task all: [:brouillon, :en_construction, :en_instruction, :accepte, :refuse, :sans_suite] do
  end

  task revert: :environment do
    Dossier.with_hidden.where(state: 'brouillon').update_all(state: 'draft')
    Dossier.with_hidden.where(state: 'en_construction').update_all(state: 'initiated')
    Dossier.with_hidden.where(state: 'en_instruction').update_all(state: 'received')
    Dossier.with_hidden.where(state: 'accepte').update_all(state: 'closed')
    Dossier.with_hidden.where(state: 'refuse').update_all(state: 'refused')
    Dossier.with_hidden.where(state: 'sans_suite').update_all(state: 'without_continuation')
  end
end
