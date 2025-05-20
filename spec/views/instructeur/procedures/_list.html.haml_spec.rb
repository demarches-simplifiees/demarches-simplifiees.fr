# frozen_string_literal: true

describe 'instructeurs/procedures/_list', type: :view do
  let(:procedure) { create(:procedure, id: 1, procedure_expires_when_termine_enabled: expiration_enabled) }
  let(:current_administrateur) { create(:administrateur) }
  let(:current_instructeur) { create(:instructeur) }

  before do
    allow(view).to receive(:current_administrateur).and_return(current_administrateur)
    allow(view).to receive(:current_instructeur).and_return(current_instructeur)
  end

  subject do
    render('instructeurs/procedures/list',
            p: procedure,
            dossiers_count_per_procedure: 5,
            dossiers_a_suivre_count_per_procedure: 2,
            dossiers_archived_count_per_procedure: 1,
            dossiers_termines_count_per_procedure: 1,
            dossiers_supprimes_count_per_procedure: 0,
            dossiers_expirant_count_per_procedure: 0,
            followed_dossiers_count_per_procedure: 0,
            procedure_ids_en_cours_with_notifications: [],
            procedure_ids_termines_with_notifications: [],
            notifications_counts_per_procedure: [])
  end

  context 'when procedure_expires_when_termine_enabled is true' do
    let(:expiration_enabled) { true }
    it 'contains link to expiring dossiers within procedure' do
      expect(subject).to have_selector(%Q(a[href="#{instructeur_procedure_path(procedure, statut: 'expirant')}"]), count: 1)
    end
  end

  context 'when procedure_expires_when_termine_enabled is false' do
    let(:expiration_enabled) { false }
    it 'does not contain link to expiring dossiers within procedure' do
      expect(subject).to have_selector(%Q(a[href="#{instructeur_procedure_path(procedure, statut: 'expirant')}"]), count: 0)
    end

    it 'contains copy link' do
      expect(subject).to have_selector('.fr-icon-clipboard-line')
    end

    it 'contains procedure number' do
      expect(subject).to have_text(procedure.id)
    end
  end
end
