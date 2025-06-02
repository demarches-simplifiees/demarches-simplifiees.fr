# frozen_string_literal: true

describe 'layouts/_header', type: :view do
  let(:current_instructeur) { nil }

  before do
    allow(view).to receive(:multiple_devise_profile_connect?).and_return(false)
    allow(view).to receive(:instructeur_signed_in?).and_return((profile == :instructeur))
    allow(view).to receive(:current_instructeur).and_return(current_instructeur)
    allow(view).to receive(:administrateur_signed_in?).and_return(false)
    allow(view).to receive(:expert_signed_in?).and_return(false)
    allow(view).to receive(:localization_enabled?).and_return(false)

    if user
      sign_in user
      allow(controller).to receive(:nav_bar_profile).and_return(profile)
    end
  end

  subject { render }

  context 'when rendering without context' do
    let(:user) { nil }
    let(:profile) { nil }

    it { is_expected.to have_css(".fr-header__operator") }
    it { is_expected.to_not have_css(".account-btn") }

    it 'displays the Help link' do
      expect(subject).to have_link('Aide', href: I18n.t("links.common.faq.url"))
    end

    context 'when on a procedure page' do
      let(:procedure) { create(:procedure, :with_service) }

      before do
        allow(controller).to receive(:procedure_for_help).and_return(procedure)
      end

      it 'displays the Help dropdown menu' do
        expect(subject).to have_css(".help-dropdown")
      end
    end
  end

  context 'when rendering for user' do
    let(:user) { create(:user) }
    let(:profile) { :user }

    it { is_expected.to have_css(".fr-header__operator") }
    it { is_expected.to have_link("Mes dossiers", href: dossiers_path) }
    it { is_expected.to have_selector(:button, user.email, class: "account-btn") }

    it 'displays the Help button' do
      expect(subject).to have_link("Aide", href: I18n.t("links.common.faq.url"))
    end
  end

  context 'when rendering for instructeur' do
    let(:instructeur) { create(:instructeur) }
    let(:user) { instructeur.user }
    let(:profile) { :instructeur }
    let(:current_instructeur) { instructeur }
    let!(:release_note) { create(:release_note, categories: ['instructeur']) }

    it { is_expected.to have_css(".fr-header__operator") }
    it { is_expected.to have_selector(:button, user.email, class: "account-btn") }

    it 'displays the Help dropdown menu' do
      expect(subject).to have_css(".help-dropdown")
    end
  end
end
