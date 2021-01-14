RSpec.describe Avis, type: :model do
  let(:claimant) { create(:instructeur) }

  describe '#email_to_display' do
    let(:invited_email) { 'invited@avis.com' }
    let!(:avis) do
      avis = create(:avis, email: invited_email, dossier: create(:dossier))
      avis.instructeur = nil
      avis
    end

    subject { avis.email_to_display }

    context 'when instructeur is not known' do
      it { is_expected.to eq(invited_email) }
    end

    context 'when instructeur is known' do
      let!(:avis) { create(:avis, email: nil, instructeur: create(:instructeur), dossier: create(:dossier)) }

      it { is_expected.to eq(avis.instructeur.email) }
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

  describe ".link_avis_to_instructeur" do
    let(:instructeur) { create(:instructeur) }

    subject { Avis.link_avis_to_instructeur(instructeur) }

    context 'when there are 2 avis linked by email to a instructeur' do
      let!(:avis) { create(:avis, email: instructeur.email, instructeur: nil) }
      let!(:avis2) { create(:avis, email: instructeur.email, instructeur: nil) }

      before do
        subject
        avis.reload
        avis2.reload
      end

      it { expect(avis.email).to be_nil }
      it { expect(avis.instructeur).to eq(instructeur) }
      it { expect(avis2.email).to be_nil }
      it { expect(avis2.instructeur).to eq(instructeur) }
    end
  end

  describe "an avis is linked to an expert" do
    let(:expert) { create(:expert) }

    context 'when there are 2 avis linked by email to a instructeur' do
      let!(:avis) { create(:avis, email: nil, expert: expert) }
      let!(:avis2) { create(:avis, email: nil, expert: expert) }

      before do
        avis.reload
        avis2.reload
      end

      it { expect(avis.email).to be_nil }
      it { expect(avis.expert).to eq(expert) }
      it { expect(avis2.email).to be_nil }
      it { expect(avis2.expert).to eq(expert) }
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

  describe '#try_to_assign_instructeur' do
    let!(:instructeur) { create(:instructeur) }
    let(:avis) { create(:avis, claimant: claimant, email: email, dossier: create(:dossier)) }

    context 'when the email belongs to a instructeur' do
      let(:email) { instructeur.email }

      it { expect(avis.instructeur).to eq(instructeur) }
      it { expect(avis.email).to be_nil }
    end

    context 'when the email does not belongs to a instructeur' do
      let(:email) { 'unknown@email' }

      it { expect(avis.instructeur).to be_nil }
      it { expect(avis.email).to eq(email) }
    end
  end

  describe "email sanitization" do
    subject { Avis.create(claimant: claimant, email: email, dossier: create(:dossier), instructeur: create(:instructeur)) }

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
    let(:expert) { create(:instructeur) }
    let(:another_expert) { create(:instructeur) }

    context "when avis claimed by an expert" do
      let(:avis) { create(:avis, dossier: dossier, claimant: claimant_expert, instructeur: expert) }
      let(:another_avis) { create(:avis, dossier: dossier, claimant: instructeur, instructeur: another_expert) }
      it "is revokable by this expert or any instructeurs of the dossier" do
        expect(avis.revokable_by?(claimant_expert)).to be_truthy
        expect(avis.revokable_by?(another_expert)).to be_falsy
        expect(avis.revokable_by?(instructeur)).to be_truthy
      end
    end

    context "when avis claimed by an instructeur" do
      let(:avis) { create(:avis, dossier: dossier, claimant: instructeur, instructeur: expert) }
      let(:another_avis) { create(:avis, dossier: dossier, claimant: expert, instructeur: another_expert) }
      let(:another_instructeur) { create(:instructeur) }
      let(:instructeurs) { [instructeur, another_instructeur] }

      it "is revokable by any instructeur of the dossier, not by an expert" do
        expect(avis.revokable_by?(instructeur)).to be_truthy
        expect(avis.revokable_by?(another_expert)).to be_falsy
        expect(avis.revokable_by?(another_instructeur)).to be_truthy
      end
    end
  end

  describe '#invited_expert_emails' do
    let!(:procedure) { create(:procedure, :published) }

    subject { Avis.invited_expert_emails(procedure) }

    context 'when there is one dossier' do
      let!(:dossier) { create(:dossier, procedure: procedure) }

      context 'when a procedure has one avis and unknown instructeur' do
        let!(:avis) { create(:avis, dossier: dossier, email: 'expert@expert.com') }

        it { is_expected.to eq(['expert@expert.com']) }
      end

      context 'when a procedure has one avis and known instructeur' do
        let!(:avis) { create(:avis, dossier: dossier, instructeur: create(:instructeur, email: 'expert@expert.com')) }

        it { is_expected.to eq(['expert@expert.com']) }
      end

      context 'when a dossier has 2 avis from the same expert' do
        let!(:avis) { create(:avis, dossier: dossier, email: 'expert@expert.com') }
        let!(:avis2) { create(:avis, dossier: dossier, email: 'expert@expert.com') }

        it { is_expected.to eq(['expert@expert.com']) }
      end
    end

    context 'when there are two dossiers' do
      let!(:dossier) { create(:dossier, procedure: procedure) }
      let!(:dossier2) { create(:dossier, procedure: procedure) }

      context 'and each one has an avis from 3 different experts' do
        let!(:avis) { create(:avis, dossier: dossier, instructeur: create(:instructeur, email: '2_expert@expert.com')) }
        let!(:unaffected_avis) { create(:avis, dossier: dossier2, email: '3_expert@expert.com') }
        let!(:unaffected_avis2) { create(:avis, dossier: dossier2, email: '1_expert@expert.com') }

        it { is_expected.to eq(['1_expert@expert.com', '2_expert@expert.com', '3_expert@expert.com']) }
      end
    end
  end
end
