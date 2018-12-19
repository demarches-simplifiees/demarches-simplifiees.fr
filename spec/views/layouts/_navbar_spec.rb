require 'spec_helper'

describe 'layouts/_navbar.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }

  describe 'polynesian layout' do
    before do
      render
    end
    subject { rendered }
    it { is_expected.to have_css('img[src*="logo-md"]') }
    it { is_expected.to have_css('.col-xs-9') }
  end

  describe 'navbar entries' do
    context 'when disconnected' do
      before do
        render
      end
      subject { rendered }
      it { is_expected.to match(/Connexion/) }
    end

    context 'when administrateur is connected' do
      before do
        @request.env["devise.mapping"] = Devise.mappings[:administrateur]
        @current_user = administrateur
        sign_in @current_user
        render
      end

      subject { rendered }
      it { is_expected.to match(/Déconnexion/) }
    end

    context 'when gestionnaire is connected' do
      before do
        @request.env["devise.mapping"] = Devise.mappings[:gestionnaire]
        @current_user = gestionnaire
        sign_in @current_user
        render
      end

      subject { rendered }
      it { is_expected.to match(/Déconnexion/) }
    end
  end
end
