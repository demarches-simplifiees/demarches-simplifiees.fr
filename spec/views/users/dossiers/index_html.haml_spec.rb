require 'spec_helper'

describe 'users/dossiers/index.html.haml', type: :view do
  let(:user) { create(:user) }

  let!(:dossier) { create(:dossier, :with_entreprise, user: user, state: 'initiated').decorate }
  let!(:dossier_2) { create(:dossier, :with_entreprise, user: user, state: 'replied').decorate }
  let!(:dossier_3) { create(:dossier, :with_entreprise, user: user, state: 'replied').decorate }
  let!(:dossier_termine) { create(:dossier, :with_entreprise, user: user, state: 'closed').decorate }

  before do
    dossier_2.entreprise.update_column(:raison_sociale, 'plip')
    dossier_2.entreprise.update_column(:raison_sociale, 'plop')
    dossier_3.entreprise.update_column(:raison_sociale, 'plup')
    dossier_termine.entreprise.update_column(:raison_sociale, 'plap')
  end

  describe 'params liste is a_traiter' do
    let(:dossiers_list) { user.dossiers.waiting_for_user('DESC') }

    before do
      sign_in user

      assign(:dossiers, (smart_listing_create :dossiers,
                                              user.dossiers.waiting_for_user('DESC'),
                                              partial: "users/dossiers/list",
                                              array: true))
      assign(:liste, 'a_traiter')
      assign(:dossiers_a_traiter_total, '1')
      assign(:dossiers_en_attente_total, '2')
      assign(:dossiers_termine_total, '1')

      render
    end

    subject { rendered }

    it { is_expected.to have_css('#users_index') }

    describe 'dossier replied is present' do
      it { is_expected.to have_content(dossier_2.procedure.libelle) }
      it { is_expected.to have_content(dossier_2.entreprise.raison_sociale) }
      it { is_expected.to have_content(dossier_2.display_state) }
      it { is_expected.to have_content(dossier_2.last_update) }
    end

    describe 'dossier initiated and closed are not present' do
      it { is_expected.not_to have_content(dossier.entreprise.raison_sociale) }
      it { is_expected.not_to have_content(dossier_termine.entreprise.raison_sociale) }
    end

    describe 'badges on tabs' do
      it { is_expected.to have_content('À traiter 1') }
      it { is_expected.to have_content('En attente 2') }
      it { is_expected.to have_content('Terminé 1') }
    end
  end

  describe 'params liste is en_attente' do
    let(:dossiers_list) { user.dossiers.waiting_for_gestionnaire('DESC') }

    before do
      sign_in user

      assign(:dossiers, (smart_listing_create :dossiers,
                                              user.dossiers.waiting_for_gestionnaire('DESC'),
                                              partial: "users/dossiers/list",
                                              array: true))
      assign(:liste, 'en_attente')
      render
    end

    subject { rendered }

    it { is_expected.to have_css('#users_index') }

    describe 'dossier initiated is present' do
      it { is_expected.to have_content(dossier.procedure.libelle) }
      it { is_expected.to have_content(dossier.entreprise.raison_sociale) }
      it { is_expected.to have_content(dossier.display_state) }
      it { is_expected.to have_content(dossier.last_update) }
    end

    describe 'dossier replied and closed are not present' do
      it { is_expected.not_to have_content(dossier_2.entreprise.raison_sociale) }
      it { is_expected.not_to have_content(dossier_termine.entreprise.raison_sociale) }
    end
  end

  describe 'params liste is termine' do
    let(:dossiers_list) { user.dossiers.termine('DESC') }

    before do
      sign_in user

      assign(:dossiers, (smart_listing_create :dossiers,
                                              user.dossiers.termine('DESC'),
                                              partial: "users/dossiers/list",
                                              array: true))
      assign(:liste, 'termine')
      render
    end

    subject { rendered }

    it { is_expected.to have_css('#users_index') }

    describe 'dossier termine is present' do
      it { is_expected.to have_content(dossier_termine.procedure.libelle) }
      it { is_expected.to have_content(dossier_termine.entreprise.raison_sociale) }
      it { is_expected.to have_content(dossier_termine.display_state) }
      it { is_expected.to have_content(dossier_termine.last_update) }
    end

    describe 'dossier initiated and replied are not present' do
      it { is_expected.not_to have_content(dossier.entreprise.raison_sociale) }
      it { is_expected.not_to have_content(dossier_2.entreprise.raison_sociale) }
    end
  end
end