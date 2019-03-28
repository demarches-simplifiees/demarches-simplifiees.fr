require 'spec_helper'

describe 'layouts/_new_header.html.haml', type: :view do
  before do
    if user
      sign_in user
      allow(controller).to receive(:nav_bar_profile).and_return(profile)
    end
  end

  subject { render }

  context 'when rendering without context' do
    let(:user) { nil }
    let(:profile) { nil }

    it { is_expected.to have_css("a.header-logo[href=\"#{root_path}\"]") }

    it 'displays the Help link' do
      expect(subject).to have_link('Aide', href: FAQ_URL)
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

    it { is_expected.to have_css("a.header-logo[href=\"#{dossiers_path}\"]") }
    it { is_expected.to have_link("Dossiers", href: dossiers_path) }

    it 'displays the Help button' do
      expect(subject).to have_link("Aide", href: FAQ_URL)
    end
  end

  context 'when rendering for gestionnaire' do
    let(:user) { create(:gestionnaire) }
    let(:profile) { :gestionnaire }

    it { is_expected.to have_css("a.header-logo[href=\"#{gestionnaire_procedures_path}\"]") }

    it 'displays the Help dropdown menu' do
      expect(subject).to have_css(".help-dropdown")
    end
  end
end
