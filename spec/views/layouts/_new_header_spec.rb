require 'spec_helper'

describe 'layouts/_new_header.html.haml', type: :view do
  describe 'logo link' do
    before do
      sign_in user
      allow(controller).to receive(:nav_bar_profile).and_return(profile)
      render
    end

    subject { rendered }

    context 'when rendering for user' do
      let(:user) { create(:user) }
      let(:profile) { :user }

      it { is_expected.to have_css("a.header-logo[href=\"#{dossiers_path}\"]") }
      it { is_expected.to have_link("Dossiers", href: dossiers_path) }
    end

    context 'when rendering for gestionnaire' do
      let(:user) { create(:gestionnaire) }
      let(:profile) { :gestionnaire }

      it { is_expected.to have_css("a.header-logo[href=\"#{gestionnaire_procedures_path}\"]") }

      it "displays the contact infos" do
        expect(rendered).to have_text("Contact")
        expect(rendered).to have_link("par email", href: contact_url)
      end
    end
  end
end
