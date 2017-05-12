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

  describe ".link_avis_to_gestionnaire" do
    let(:gestionnaire){ create(:gestionnaire) }

    subject{ Avis.link_avis_to_gestionnaire(gestionnaire) }

    context 'when there are 2 avis linked by email to a gestionnaire' do
      let!(:avis){ create(:avis, email: gestionnaire.email, gestionnaire: nil) }
      let!(:avis2){ create(:avis, email: gestionnaire.email, gestionnaire: nil) }

      before do
        subject
        avis.reload
        avis2.reload
      end

      it { expect(avis.email).to be_nil }
      it { expect(avis.gestionnaire).to eq(gestionnaire) }
      it { expect(avis2.email).to be_nil }
      it { expect(avis2.gestionnaire).to eq(gestionnaire) }
    end
  end

  describe '.avis_exists_and_email_belongs_to_avis' do
    let(:dossier) { create(:dossier) }
    let(:invited_email) { 'invited@avis.com' }
    let!(:avis) { Avis.create(email: invited_email, dossier: dossier) }

    subject { Avis.avis_exists_and_email_belongs_to_avis?(avis_id, email) }

    context 'when the avis is unknown' do
      let(:avis_id) { 666 }
      let(:email) { 'unknown@mystery.com' }

      it { is_expected.to be false }
    end

    context 'when the avis is known' do
      let(:avis_id) { avis.id }

      context 'when the email belongs to the invitation' do
        let(:email) { invited_email }
        it { is_expected.to be true }
      end

      context 'when the email is unknown' do
        let(:email) { 'unknown@mystery.com' }
        it { is_expected.to be false }
      end
    end
  end
end
