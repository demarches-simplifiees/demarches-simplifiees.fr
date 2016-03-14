require 'spec_helper'

describe 'backoffice/dossiers/index.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateur: administrateur) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }

  let!(:decorate_dossier_initiated) { create(:dossier, procedure: procedure, nom_projet: 'projet initiated', state: 'initiated').decorate }
  let!(:decorate_dossier_replied) { create(:dossier, procedure: procedure, nom_projet: 'projet replied', state: 'replied').decorate }
  let!(:decorate_dossier_closed) { create(:dossier, procedure: procedure, nom_projet: 'projet closed', state: 'closed').decorate }

  describe 'on tab a_traiter' do
    before do
      assign(:dossiers, (smart_listing_create :dossiers,
                                              gestionnaire.dossiers.waiting_for_gestionnaire,
                                              partial: "backoffice/dossiers/list",
                                              array: true))
      assign(:liste, 'a_traiter')
      assign(:a_traiter_class, 'active')

      render
    end

    subject { rendered }
    it { is_expected.to have_css('#backoffice_index') }
    it { is_expected.to have_content(procedure.libelle) }
    it { is_expected.to have_content(decorate_dossier_initiated.nom_projet) }
    it { is_expected.to have_content(decorate_dossier_initiated.display_state) }
    it { is_expected.to have_content(decorate_dossier_initiated.last_update) }

    it { is_expected.not_to have_content(decorate_dossier_replied.nom_projet) }
    it { is_expected.not_to have_content(decorate_dossier_closed.nom_projet) }

    describe 'active tab' do
      it { is_expected.to have_selector('.active .text-danger') }
    end
  end

  describe 'on tab en_attente' do
    before do
      assign(:dossiers, (smart_listing_create :dossiers,
                                              gestionnaire.dossiers.waiting_for_user,
                                              partial: "backoffice/dossiers/list",
                                              array: true))
      assign(:liste, 'en_attente')
      assign(:en_attente_class, 'active')

      render
    end

    subject { rendered }
    it { is_expected.to have_css('#backoffice_index') }
    it { is_expected.to have_content(procedure.libelle) }
    it { is_expected.to have_content(decorate_dossier_replied.nom_projet) }
    it { is_expected.to have_content(decorate_dossier_replied.display_state) }
    it { is_expected.to have_content(decorate_dossier_replied.last_update) }

    it { is_expected.not_to have_content(decorate_dossier_initiated.nom_projet) }
    it { is_expected.not_to have_content(decorate_dossier_closed.nom_projet) }

    describe 'active tab' do
      it { is_expected.to have_selector('.active .text-info') }
    end
  end

  describe 'on tab termine' do
    before do
      assign(:dossiers, (smart_listing_create :dossiers,
                                              gestionnaire.dossiers.termine,
                                              partial: "backoffice/dossiers/list",
                                              array: true))
      assign(:termine_class, 'active')
      assign(:liste, 'termine')
      render
    end

    subject { rendered }

    it { is_expected.to have_css('#backoffice_index') }
    it { is_expected.to have_content(procedure.libelle) }
    it { is_expected.to have_content(decorate_dossier_closed.nom_projet) }
    it { is_expected.to have_content(decorate_dossier_closed.display_state) }
    it { is_expected.to have_content(decorate_dossier_closed.last_update) }

    it { is_expected.not_to have_content(decorate_dossier_initiated.nom_projet) }
    it { is_expected.not_to have_content(decorate_dossier_replied.nom_projet) }

    describe 'active tab' do
      it { is_expected.to have_selector('.active .text-success') }
    end
  end
end