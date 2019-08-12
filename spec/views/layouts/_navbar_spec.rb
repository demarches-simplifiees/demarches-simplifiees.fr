require 'spec_helper'

describe 'layouts/_navbar.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:instructeur) { create(:instructeur, administrateurs: [administrateur]) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }

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

    context 'when instructeur is connected' do
      before do
        @request.env["devise.mapping"] = Devise.mappings[:instructeur]
        @current_user = instructeur
        sign_in @current_user
        render
      end

      subject { rendered }
      it { is_expected.to match(/Déconnexion/) }
    end
  end
end
