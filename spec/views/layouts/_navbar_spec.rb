require 'spec_helper'

describe 'layouts/_navbar.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }

  describe 'navbar entries' do

    context 'when disconnected' do
      before do
        render
      end
      subject { rendered }
      it { is_expected.to match(/href="\/users\/sign_in">Utilisateur/) }
      it { is_expected.to match(/href="\/gestionnaires\/sign_in">Accompagnateur/) }
      it { is_expected.to match(/href="\/administrateurs\/sign_in">Administrateur/) }
      it { is_expected.not_to match(/Mes Dossiers/) }
      it { is_expected.not_to match(/Se déconnecter/) }
    end

    context 'when administrateur is connected' do
      before do
        @request.env["devise.mapping"] = Devise.mappings[:administrateur]
        @current_user = administrateur
        sign_in @current_user
        render
      end

      subject { rendered }
      it { is_expected.not_to match(/href="\/users\/sign_in">Utilisateur/) }
      it { is_expected.not_to match(/href="\/gestionnaires\/sign_in">Accompagnateur/) }
      it { is_expected.not_to match(/href="\/administrateurs\/sign_in">Administrateur/) }
      it { is_expected.not_to match(/Mes Dossiers/) }
      it { is_expected.to match(/Se déconnecter/) }
    end

    context 'when gestionnaire is connected' do
      before do
        @request.env["devise.mapping"] = Devise.mappings[:gestionnaire]
        @current_user = gestionnaire
        sign_in @current_user
        render
      end

      subject { rendered }
      it { is_expected.not_to match(/href="\/users\/sign_in">Utilisateur/) }
      it { is_expected.not_to match(/href="\/gestionnaires\/sign_in">Accompagnateur/) }
      it { is_expected.not_to match(/href="\/administrateurs\/sign_in">Administrateur/) }
      it { is_expected.to match(/Mes Dossiers/) }
      it { is_expected.to match(/Se déconnecter/) }
    end

  end
end
