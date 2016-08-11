require 'spec_helper'

describe 'backoffice/dossiers/index.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }

  let!(:decorate_dossier_initiated) { create(:dossier, :with_entreprise, procedure: procedure, state: 'initiated').decorate }
  let!(:decorate_dossier_replied) { create(:dossier, :with_entreprise, procedure: procedure, state: 'replied').decorate }
  let!(:decorate_dossier_updated) { create(:dossier, :with_entreprise, procedure: procedure, state: 'updated').decorate }
  let!(:decorate_dossier_validated) { create(:dossier, :with_entreprise, procedure: procedure, state: 'validated').decorate }
  let!(:decorate_dossier_submitted) { create(:dossier, :with_entreprise, procedure: procedure, state: 'submitted').decorate }
  let!(:decorate_dossier_received) { create(:dossier, :with_entreprise, procedure: procedure, state: 'received').decorate }
  let!(:decorate_dossier_closed) { create(:dossier, :with_entreprise, procedure: procedure, state: 'closed').decorate }
  let!(:decorate_dossier_refused) { create(:dossier, :with_entreprise, procedure: procedure, state: 'refused').decorate }
  let!(:decorate_dossier_without_continuation) { create(:dossier, :with_entreprise, procedure: procedure, state: 'without_continuation').decorate }

  before do
    decorate_dossier_replied.entreprise.update_column(:raison_sociale, 'plap')
    decorate_dossier_updated.entreprise.update_column(:raison_sociale, 'plep')
    decorate_dossier_validated.entreprise.update_column(:raison_sociale, 'plip')
    decorate_dossier_submitted.entreprise.update_column(:raison_sociale, 'plop')
    decorate_dossier_received.entreprise.update_column(:raison_sociale, 'plup')
    decorate_dossier_closed.entreprise.update_column(:raison_sociale, 'plyp')
    decorate_dossier_refused.entreprise.update_column(:raison_sociale, 'plzp')
    decorate_dossier_without_continuation.entreprise.update_column(:raison_sociale, 'plnp')

    create :preference_list_dossier,
           gestionnaire: gestionnaire,
           table: '',
           attr: 'state',
           attr_decorate: 'display_state'

    create :preference_list_dossier,
           gestionnaire: gestionnaire,
           table: 'procedure',
           attr: 'libelle',
           attr_decorate: 'libelle'

    create :preference_list_dossier,
           gestionnaire: gestionnaire,
           table: 'entreprise',
           attr: 'raison_sociale',
           attr_decorate: 'raison_sociale'

    create :preference_list_dossier,
           gestionnaire: gestionnaire,
           table: '',
           attr: 'last_update',
           attr_decorate: 'last_update'

    create :assign_to, gestionnaire: gestionnaire, procedure: procedure
    sign_in gestionnaire
  end

  shared_examples 'check_tab_content' do
    before do
      assign :dossiers_list_facade, (DossiersListFacades.new gestionnaire, liste)
      assign(:dossiers, (smart_listing_create :dossiers,
                                              dossiers_to_display,
                                              partial: "backoffice/dossiers/list",
                                              array: true))
      render
    end

    subject { rendered }

    describe 'pref list column' do
      it { is_expected.to have_css('#backoffice_index') }
      it { is_expected.to have_content(procedure.libelle) }
      it { is_expected.to have_content(decorate_dossier_at_check.entreprise.raison_sociale) }
      it { is_expected.to have_content(decorate_dossier_at_check.display_state) }
      it { is_expected.to have_content(decorate_dossier_at_check.last_update) }
    end

    it { is_expected.to have_css("#suivre_dossier_#{dossiers_to_display.first.id}") }

    it { expect(dossiers_to_display.count).to eq total_dossiers }

    describe 'active tab' do
      it { is_expected.to have_selector(active_class) }
    end
  end

  describe 'on tab nouveaux' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-info' }
    let(:dossiers_to_display) { gestionnaire.dossiers.nouveaux }
    let(:liste) { 'nouveaux' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_initiated }
    end
  end

  describe 'on tab a_traiter' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-danger' }
    let(:dossiers_to_display) { gestionnaire.dossiers.waiting_for_gestionnaire }
    let(:liste) { 'a_traiter' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_updated }
    end
  end

  describe 'on tab en_attente' do
    let(:total_dossiers) { 2 }
    let(:active_class) { '.active .text-default' }
    let(:dossiers_to_display) { gestionnaire.dossiers.waiting_for_user }
    let(:liste) { 'en_attente' }

    describe 'for state replied' do
      it_behaves_like 'check_tab_content' do
        let(:decorate_dossier_at_check) { decorate_dossier_replied }
      end
    end

    describe 'for state validated' do
      it_behaves_like 'check_tab_content' do
        let(:decorate_dossier_at_check) { decorate_dossier_validated }
      end
    end
  end

  describe 'on tab deposes' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-purple' }
    let(:dossiers_to_display) { gestionnaire.dossiers.deposes }
    let(:liste) { 'deposes' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_submitted }
    end
  end

  describe 'on tab a_instruire' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-warning' }
    let(:dossiers_to_display) { gestionnaire.dossiers.a_instruire }
    let(:liste) { 'a_instruire' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_received }
    end
  end

  describe 'on tab termine' do
    let(:total_dossiers) { 3 }
    let(:active_class) { '.active .text-success' }
    let(:dossiers_to_display) { gestionnaire.dossiers.termine }
    let(:liste) { 'termine' }

    describe 'for state closed' do
      it_behaves_like 'check_tab_content' do
        let(:decorate_dossier_at_check) { decorate_dossier_closed }
      end
    end

    describe 'for state refused' do
      it_behaves_like 'check_tab_content' do
        let(:decorate_dossier_at_check) { decorate_dossier_refused }
      end
    end

    describe 'for state without_continuation' do
      it_behaves_like 'check_tab_content' do
        let(:decorate_dossier_at_check) { decorate_dossier_without_continuation }
      end
    end
  end
end