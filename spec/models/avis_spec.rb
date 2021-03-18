RSpec.describe Avis, type: :model do
  let(:claimant) { create(:instructeur) }

  describe '#email_to_display' do
    let(:invited_email) { 'invited@avis.com' }
    let(:expert) { create(:expert) }
    let(:procedure) { create(:procedure) }
    let(:experts_procedure) { ExpertsProcedure.create(expert: expert, procedure: procedure) }

    subject { avis.email_to_display }

    context 'when expert is known' do
      let!(:avis) { create(:avis, claimant: claimant, dossier: create(:dossier), experts_procedure: experts_procedure) }

      it { is_expected.to eq(avis.expert.email) }
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

  describe "an avis is linked to an expert_procedure" do
    let(:procedure) { create(:procedure) }
    let(:expert) { create(:expert) }
    let(:experts_procedure) { ExpertsProcedure.create(procedure: procedure, expert: expert) }

    context 'an avis is linked to an experts_procedure' do
      let!(:avis) { create(:avis, email: nil, experts_procedure: experts_procedure) }

      before do
        avis.reload
      end

      it { expect(avis.email).to be_nil }
      it { expect(avis.experts_procedure).to eq(experts_procedure) }
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

  describe "email sanitization" do
    let(:expert) { create(:expert) }
    let(:procedure) { create(:procedure) }
    let!(:experts_procedure) { ExpertsProcedure.create(expert: expert, procedure: procedure) }
    subject { Avis.create(claimant: claimant, email: email, experts_procedure: experts_procedure, dossier: create(:dossier)) }

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

  describe ".revoke_by!" do
    let(:claimant) { create(:instructeur) }

    context "when no answer" do
      let(:avis) { create(:avis, claimant: claimant) }

      it "supprime l'avis" do
        avis.revoke_by!(claimant)
        expect(avis).to be_destroyed
        expect(Avis.count).to eq 0
      end
    end

    context "with answer" do
      let(:avis) { create(:avis, :with_answer, claimant: claimant) }

      it "revoque l'avis" do
        avis.revoke_by!(claimant)
        expect(avis).not_to be_destroyed
        expect(avis).to be_revoked
      end
    end

    context "by an instructeur who can't revoke" do
      let(:avis) { create(:avis, :with_answer, claimant: claimant) }
      let(:expert) { create(:instructeur) }

      it "doesn't revoke avis and returns false" do
        result = avis.revoke_by!(expert)
        expect(result).to be_falsey
        expect(avis).not_to be_destroyed
        expect(avis).not_to be_revoked
      end
    end
  end

  describe "revokable_by?" do
    let(:instructeur) { create(:instructeur) }
    let(:instructeurs) { [instructeur] }
    let(:procedure) { create(:procedure, :published, instructeurs: instructeurs) }
    let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }
    let(:claimant_expert) { create(:instructeur) }
    let(:expert) { create(:expert) }
    let(:experts_procedure) { ExpertsProcedure.create(expert: expert, procedure: procedure) }
    let(:another_expert) { create(:expert) }

    context "when avis claimed by an expert" do
      let(:avis) { create(:avis, dossier: dossier, claimant: claimant_expert, experts_procedure: experts_procedure) }
      let(:another_avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure) }
      it "is revokable by this expert or any instructeurs of the dossier" do
        expect(avis.revokable_by?(claimant_expert)).to be_truthy
        expect(avis.revokable_by?(another_expert)).to be_falsy
        expect(avis.revokable_by?(instructeur)).to be_truthy
      end
    end

    context "when avis claimed by an instructeur" do
      let(:expert) { create(:expert) }
      let(:expert_2) { create(:expert) }
      let!(:procedure) { create(:procedure, :published, instructeurs: instructeurs) }
      let(:experts_procedure) { ExpertsProcedure.create(expert: expert, procedure: procedure) }
      let(:experts_procedure_2) { ExpertsProcedure.create(expert: expert_2, procedure: procedure) }
      let(:avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure) }
      let(:another_avis) { create(:avis, dossier: dossier, claimant: expert, experts_procedure: experts_procedure_2) }
      let(:another_instructeur) { create(:instructeur) }
      let(:instructeurs) { [instructeur, another_instructeur] }

      it "is revokable by any instructeur of the dossier, not by an expert" do
        expect(avis.revokable_by?(instructeur)).to be_truthy
        expect(avis.revokable_by?(another_expert)).to be_falsy
        expect(avis.revokable_by?(another_instructeur)).to be_truthy
      end
    end
  end
end
