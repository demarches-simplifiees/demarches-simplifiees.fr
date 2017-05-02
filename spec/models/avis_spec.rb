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

  describe '.by_latest' do
    context 'with 3 avis' do
      let!(:avis){ create(:avis) }
      let!(:avis2){ create(:avis, updated_at: 4.hours.ago) }
      let!(:avis3){ create(:avis, updated_at: 3.hours.ago) }

      subject { Avis.by_latest }

      it { expect(subject).to eq([avis, avis3, avis2])}
    end
  end
end
