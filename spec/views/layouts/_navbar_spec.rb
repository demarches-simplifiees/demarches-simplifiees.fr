require 'spec_helper'

describe 'layouts/_navbar.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:instructeur) { create(:instructeur, administrateurs: [administrateur]) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }

  before do
    allow(view).to receive(:instructeur_signed_in?).and_return(instructeur_signed_in)
    allow(view).to receive(:administrateur_signed_in?).and_return(administrateur_signed_in)
  end

  describe 'navbar entries' do
    before { render }

    subject { rendered }

    context 'when disconnected' do
      let(:instructeur_signed_in) { false }
      let(:administrateur_signed_in) { false }

      it { is_expected.to match(/Connexion/) }
    end

    context 'when administrateur is connected' do
      let(:instructeur_signed_in) { false }
      let(:administrateur_signed_in) { true }

      it { is_expected.to match(/Déconnexion/) }
    end

    context 'when instructeur is connected' do
      let(:instructeur_signed_in) { true }
      let(:administrateur_signed_in) { false }

      it { is_expected.to match(/Déconnexion/) }
    end
  end
end
