require 'rails_helper'

RSpec.describe Avis, type: :model do
  describe '.email_to_display' do
    let(:invited_email) { 'invited@avis.com' }
    let!(:avis) { Avis.create(email: invited_email, dossier: create(:dossier)) }

    subject { avis.email_to_display }

    context 'when gestionnaire is not known' do
      it{ is_expected.to eq(invited_email) }
    end

    context 'when gestionnaire is known' do
      let!(:avis) { Avis.create(email: nil, gestionnaire: create(:gestionnaire), dossier: create(:dossier)) }

      it{ is_expected.to eq(avis.gestionnaire.email) }
    end
  end
end
