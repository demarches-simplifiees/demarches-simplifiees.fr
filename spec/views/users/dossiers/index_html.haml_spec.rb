require 'spec_helper'

describe 'users/dossiers/index.html.haml', type: :view do
  let(:user) { create(:user) }

  let!(:dossier) { create(:dossier, user: user, state: 'initiated', nom_projet: 'projet de test').decorate }
  let!(:dossier_2) { create(:dossier, user: user, state: 'replied', nom_projet: 'projet répondu').decorate }
  let!(:dossier_3) { create(:dossier, user: user, state: 'replied', nom_projet: 'projet répondu 2').decorate }
  let!(:dossier_termine) { create(:dossier, user: user, state: 'closed').decorate }

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
      it { is_expected.to have_content(dossier_2.nom_projet) }
      it { is_expected.to have_content(dossier_2.display_state) }
      it { is_expected.to have_content(dossier_2.last_update) }
    end

    describe 'dossier initiated and closed are not present' do
      it { is_expected.not_to have_content(dossier.nom_projet) }
      it { is_expected.not_to have_content(dossier_termine.nom_projet) }
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
      it { is_expected.to have_content(dossier.nom_projet) }
      it { is_expected.to have_content(dossier.display_state) }
      it { is_expected.to have_content(dossier.last_update) }
    end

    describe 'dossier replied and closed are not present' do
      it { is_expected.not_to have_content(dossier_2.nom_projet) }
      it { is_expected.not_to have_content(dossier_termine.nom_projet) }
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
      it { is_expected.to have_content(dossier_termine.nom_projet) }
      it { is_expected.to have_content(dossier_termine.display_state) }
      it { is_expected.to have_content(dossier_termine.last_update) }
    end

    describe 'dossier initiated and replied are not present' do
      it { is_expected.not_to have_content(dossier.nom_projet) }
      it { is_expected.not_to have_content(dossier_2.nom_projet) }
    end
  end
end