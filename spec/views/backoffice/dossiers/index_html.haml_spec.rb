require 'spec_helper'

describe 'backoffice/dossiers/index.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }

  let!(:decorate_dossier_initiated) { create(:dossier, :with_entreprise, procedure: procedure, state: 'initiated').decorate }
  let!(:decorate_dossier_replied) { create(:dossier, :with_entreprise, procedure: procedure, state: 'replied').decorate }
  let!(:decorate_dossier_closed) { create(:dossier, :with_entreprise, procedure: procedure, state: 'closed').decorate }

  before do

    decorate_dossier_closed.entreprise.update_column(:raison_sociale, 'plip')
    decorate_dossier_replied.entreprise.update_column(:raison_sociale, 'plop')

    create :assign_to, gestionnaire: gestionnaire, procedure: procedure
    sign_in gestionnaire
  end

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
    it { is_expected.to have_content(decorate_dossier_initiated.entreprise.raison_sociale) }
    it { is_expected.to have_content(decorate_dossier_initiated.display_state) }
    it { is_expected.to have_content(decorate_dossier_initiated.last_update) }

    it { is_expected.not_to have_content(decorate_dossier_replied.entreprise.raison_sociale) }
    it { is_expected.not_to have_content(decorate_dossier_closed.entreprise.raison_sociale) }

    it { is_expected.to have_css("#suivre_dossier_#{gestionnaire.dossiers.waiting_for_gestionnaire.first.id}") }

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
    it { is_expected.to have_content(decorate_dossier_replied.entreprise.raison_sociale) }
    it { is_expected.to have_content(decorate_dossier_replied.display_state) }
    it { is_expected.to have_content(decorate_dossier_replied.last_update) }

    it { is_expected.not_to have_content(decorate_dossier_initiated.entreprise.raison_sociale) }
    it { is_expected.not_to have_content(decorate_dossier_closed.entreprise.raison_sociale) }

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
    it { is_expected.to have_content(decorate_dossier_closed.entreprise.raison_sociale) }
    it { is_expected.to have_content(decorate_dossier_closed.display_state) }
    it { is_expected.to have_content(decorate_dossier_closed.last_update) }

    it { is_expected.not_to have_content(decorate_dossier_initiated.entreprise.raison_sociale) }
    it { is_expected.not_to have_content(decorate_dossier_replied.entreprise.raison_sociale) }

    it { is_expected.not_to have_css("#suivre_dossier_#{gestionnaire.dossiers.termine.first.id}") }

    describe 'active tab' do
      it { is_expected.to have_selector('.active .text-success') }
    end
  end
end