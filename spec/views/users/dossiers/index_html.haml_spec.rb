require 'spec_helper'

describe 'users/dossiers/index.html.haml', type: :view do
  let(:user) { create(:user) }

  let!(:decorate_dossier_initiated) { create(:dossier, :with_entreprise, user: user, state: 'initiated').decorate }
  let!(:decorate_dossier_replied) { create(:dossier, :with_entreprise, user: user, state: 'replied').decorate }
  let!(:decorate_dossier_updated) { create(:dossier, :with_entreprise, user: user, state: 'updated').decorate }
  let!(:decorate_dossier_validated) { create(:dossier, :with_entreprise, user: user, state: 'validated').decorate }
  let!(:decorate_dossier_submitted) { create(:dossier, :with_entreprise, user: user, state: 'submitted').decorate }
  let!(:decorate_dossier_received) { create(:dossier, :with_entreprise, user: user, state: 'received').decorate }
  let!(:decorate_dossier_closed) { create(:dossier, :with_entreprise, user: user, state: 'closed').decorate }
  let!(:decorate_dossier_refused) { create(:dossier, :with_entreprise, user: user, state: 'refused').decorate }
  let!(:decorate_dossier_without_continuation) { create(:dossier, :with_entreprise, user: user, state: 'without_continuation').decorate }
  let!(:decorate_dossier_invite) { create(:dossier, :with_entreprise, user: create(:user), state: 'initiated').decorate }

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

    describe 'active tab' do
      it { is_expected.to have_selector(active_class) }
    end
  end

  describe 'on tab nouveaux' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-info' }
    let(:dossiers_to_display) { user.dossiers.nouveaux }
    let(:liste) { 'nouveaux' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_initiated }
    end
  end

  describe 'on tab action requise' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-danger' }
    let(:dossiers_to_display) { user.dossiers.waiting_for_user_without_validated }
    let(:liste) { 'a_traiter' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_replied }
    end
  end

  describe 'on tab etude en cours' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-default' }
    let(:dossiers_to_display) { user.dossiers.waiting_for_gestionnaire }
    let(:liste) { 'en_attente' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_updated }
    end
  end

  describe 'on tab etude a deposer' do
    let(:total_dossiers) { 1 }
    let(:active_class) { '.active .text-purple' }
    let(:dossiers_to_display) { user.dossiers.valides }
    let(:liste) { 'valides' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_validated }
    end
  end

  describe 'on tab etude en examen' do
    let(:total_dossiers) { 2 }
    let(:active_class) { '.active .text-default' }
    let(:dossiers_to_display) { user.dossiers.en_instruction }
    let(:liste) { 'en_instruction' }

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_submitted }
    end

    it_behaves_like 'check_tab_content' do
      let(:decorate_dossier_at_check) { decorate_dossier_received }
    end
  end

  describe 'on tab etude termine' do
    let(:total_dossiers) { 3 }
    let(:active_class) { '.active .text-success' }
    let(:dossiers_to_display) { user.dossiers.termine }
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