require 'rails_helper'

RSpec.describe Avis, type: :model do
  let(:claimant) { create(:gestionnaire) }

  describe '#email_to_display' do
    let(:invited_email) { 'invited@avis.com' }
    let!(:avis) do
      avis = create(:avis, email: invited_email, dossier: create(:dossier))
      avis.gestionnaire = nil
      avis
    end

    subject { avis.email_to_display }

    context 'when gestionnaire is not known' do
      it { is_expected.to eq(invited_email) }
    end

    context 'when gestionnaire is known' do
      let!(:avis) { create(:avis, email: nil, gestionnaire: create(:gestionnaire), dossier: create(:dossier)) }

      it { is_expected.to eq(avis.gestionnaire.email) }
    end
  end

  describe '.by_latest' do
    context 'with 3 avis' do
      let!(:avis) { create(:avis) }
      let!(:avis2) { create(:avis, updated_at: 4.hours.ago) }
      let!(:avis3) { create(:avis, updated_at: 3.hours.ago) }

      subject { Avis.by_latest }

      it { expect(subject).to eq([avis, avis3, avis2]) }
    end
  end

  describe ".link_avis_to_gestionnaire" do
    let(:gestionnaire) { create(:gestionnaire) }

    subject { Avis.link_avis_to_gestionnaire(gestionnaire) }

    context 'when there are 2 avis linked by email to a gestionnaire' do
      let!(:avis) { create(:avis, email: gestionnaire.email, gestionnaire: nil) }
      let!(:avis2) { create(:avis, email: gestionnaire.email, gestionnaire: nil) }

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

  describe '.avis_exists_and_email_belongs_to_avis?' do
    let(:dossier) { create(:dossier) }
    let(:invited_email) { 'invited@avis.com' }
    let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }

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

  describe '#notify_gestionnaire' do
    context 'when an avis is created' do
      before do
        avis_invitation_double = double('avis_invitation', deliver_later: true)
        allow(AvisMailer).to receive(:avis_invitation).and_return(avis_invitation_double)
        Avis.create(claimant: claimant, email: 'email@l.com')
      end

      it { expect(AvisMailer).to have_received(:avis_invitation) }
    end
  end

  describe '#try_to_assign_gestionnaire' do
    let!(:gestionnaire) { create(:gestionnaire) }
    let(:avis) { Avis.create(claimant: claimant, email: email, dossier: create(:dossier)) }

    context 'when the email belongs to a gestionnaire' do
      let(:email) { gestionnaire.email }

      it { expect(avis.gestionnaire).to eq(gestionnaire) }
      it { expect(avis.email).to be_nil }
    end

    context 'when the email does not belongs to a gestionnaire' do
      let(:email) { 'unknown@email' }

      it { expect(avis.gestionnaire).to be_nil }
      it { expect(avis.email).to eq(email) }
    end
  end

  describe "email sanitization" do
    subject { Avis.create(claimant: claimant, email: email, dossier: create(:dossier), gestionnaire: create(:gestionnaire)) }

    context "when there is no email" do
      let(:email) { nil }

      it { expect(subject.email).to be_nil }
    end

    context "when the email is in lowercase" do
      let(:email) { "toto@tps.fr" }

      it { expect(subject.email).to eq("toto@tps.fr") }
    end

    context "when the email is not in lowercase" do
      let(:email) { "TOTO@tps.fr" }

      it { expect(subject.email).to eq("toto@tps.fr") }
    end

    context "when the email has some spaces before and after" do
      let(:email) { "  toto@tps.fr  " }

      it { expect(subject.email).to eq("toto@tps.fr") }
    end
  end
end
