require 'spec_helper'

describe 'users/dossiers/index.html.haml', type: :view do
  let(:user) { create(:user) }

  let!(:dossier) { create(:dossier, :with_procedure, user: user, state: 'initiated', nom_projet: 'projet de test').decorate }
  let!(:dossier_2) { create(:dossier, :with_procedure, user: user, state: 'replied', nom_projet: 'projet répondu').decorate }
  let!(:dossier_termine) { create(:dossier, :with_procedure, user: user, state: 'closed').decorate }

  describe 'params liste is a_traiter' do
    let(:dossiers_list) { user.dossiers.waiting_for_user('DESC') }

    before do
      sign_in user

      assign(:dossiers, dossiers_list.paginate(:page => 1).decorate)
      assign(:liste, 'a_traiter')
      render
    end

    subject { rendered }

    it { is_expected.to have_css('#users_index') }

    describe 'dossier replied is present' do
      it { is_expected.to have_content(dossier_2.procedure.libelle) }
      it { is_expected.to have_content(dossier_2.nom_projet) }
      it { is_expected.to have_content(dossier_2.state_fr) }
      it { is_expected.to have_content(dossier_2.last_update) }
    end

    describe 'dossier initiated and closed are not present' do
      it { is_expected.not_to have_content(dossier.nom_projet) }
      it { is_expected.not_to have_content(dossier_termine.nom_projet) }
    end
  end

  describe 'params liste is en_attente' do
    let(:dossiers_list) { user.dossiers.waiting_for_gestionnaire('DESC') }

    before do
      sign_in user

      assign(:dossiers, dossiers_list.paginate(:page => 1).decorate)
      assign(:liste, 'en_attente')
      render
    end

    subject { rendered }

    it { is_expected.to have_css('#users_index') }

    describe 'dossier initiated is present' do
      it { is_expected.to have_content(dossier.procedure.libelle) }
      it { is_expected.to have_content(dossier.nom_projet) }
      it { is_expected.to have_content(dossier.state_fr) }
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

      assign(:dossiers, dossiers_list.paginate(:page => 1).decorate)
      assign(:liste, 'termine')
      render
    end

    subject { rendered }

    it { is_expected.to have_css('#users_index') }

    describe 'dossier termine is present' do
      it { is_expected.to have_content(dossier_termine.procedure.libelle) }
      it { is_expected.to have_content(dossier_termine.nom_projet) }
      it { is_expected.to have_content(dossier_termine.state_fr) }
      it { is_expected.to have_content(dossier_termine.last_update) }
    end

    describe 'dossier initiated and replied are not present' do
      it { is_expected.not_to have_content(dossier.nom_projet) }
      it { is_expected.not_to have_content(dossier_2.nom_projet) }
    end
  end
end