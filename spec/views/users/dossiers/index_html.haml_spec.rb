require 'spec_helper'

describe 'users/dossiers/index.html.haml', type: :view do
  let(:user) { create(:user) }

  let!(:decorate_dossier_en_construction) { create(:dossier, :with_entreprise, user: user, state: 'en_construction').decorate }
  let!(:decorate_dossier_received) { create(:dossier, :with_entreprise, user: user, state: 'received').decorate }
  let!(:decorate_dossier_closed) { create(:dossier, :with_entreprise, user: user, state: 'closed').decorate }
  let!(:decorate_dossier_refused) { create(:dossier, :with_entreprise, user: user, state: 'refused').decorate }
  let!(:decorate_dossier_without_continuation) { create(:dossier, :with_entreprise, user: user, state: 'without_continuation').decorate }
  let!(:decorate_dossier_invite) { create(:dossier, :with_entreprise, user: create(:user), state: 'en_construction').decorate }

  before do
    create :invite, dossier: decorate_dossier_invite, user: user
  end

  shared_examples 'check_tab_content' do
    before do
      sign_in user

      assign :dossiers_list_facade, (DossiersListFacades.new user, liste)
      assign(:dossiers, (smart_listing_create :dossiers,
        dossiers_to_display,
        partial: "users/dossiers/list",
        array: true))
      render
    end

    subject { rendered }

    describe 'columns' do
      it { is_expected.to have_content(decorate_dossier_at_check.id) }
      it { is_expected.to have_content(decorate_dossier_at_check.procedure.libelle) }
      it { is_expected.to have_content(decorate_dossier_at_check.display_state) }
      it { is_expected.to have_content(decorate_dossier_at_check.last_update) }
    end

    it { expect(dossiers_to_display.count).to eq total_dossiers }
  end

  describe 'on tab en construction' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-danger' }
    let(:dossiers_to_display) { user.dossiers.state_en_construction }
    let(:liste) { 'a_traiter' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_en_construction }
    end
  end

  describe 'on tab etude en examen' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-default' }
    let(:dossiers_to_display) { user.dossiers.state_en_instruction }
    let(:liste) { 'en_instruction' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_received }
    end
  end

  describe 'on tab etude termine' do
    let(:total_dossiers) { 3 }
    let(:active_class) { '.active .text-success' }
    let(:dossiers_to_display) { user.dossiers.state_termine }
    let(:liste) { 'termine' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_closed }
    end

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_refused }
    end

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_without_continuation }
    end
  end

  describe 'on tab etude invite' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-warning' }
    let(:dossiers_to_display) { user.invites }
    let(:liste) { 'invite' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_invite }
    end
  end
end
