RSpec.describe DossierHelper, type: :helper do
  describe ".highlight_if_unseen_class" do
    let(:seen_at) { Time.zone.now }

    subject { highlight_if_unseen_class(seen_at, updated_at) }

    context "when commentaire date is created before last seen datetime" do
      let(:updated_at) { seen_at - 2.days }

      it { is_expected.to eq nil }
    end

    context "when commentaire date is created after last seen datetime" do
      let(:updated_at) { seen_at + 2.hours }

      it { is_expected.to eq "highlighted" }
    end

    context "when there is no last seen datetime" do
      let(:updated_at) { Time.zone.now }
      let(:seen_at) { nil }

      it { is_expected.to eq nil }
    end
  end

  describe ".url_for_dossier" do
    subject { url_for_dossier(dossier) }

    context "when the dossier is in the brouillon state" do
      let(:dossier) { create(:dossier, state: Dossier.states.fetch(:brouillon)) }
      it { is_expected.to eq "/dossiers/#{dossier.id}/brouillon" }
    end

    context "when the dossier is any other state" do
      let(:dossier) { create(:dossier, state: Dossier.states.fetch(:en_construction)) }
      it { is_expected.to eq "/dossiers/#{dossier.id}" }
    end
  end

  describe ".demandeur_dossier" do
    subject { demandeur_dossier(dossier) }

    let(:individual) { create(:individual) }
    let(:etablissement) { create(:etablissement) }
    let(:dossier) { create(:dossier, procedure: procedure, individual: individual, etablissement: etablissement) }

    context "when the dossier is for an individual" do
      let(:procedure) { create(:simple_procedure, :for_individual) }

      context "when the individual is not provided" do
        let(:individual) { nil }
        it { is_expected.to be_blank }
      end

      context "when the individual has name information" do
        it { is_expected.to eq "#{individual.nom} #{individual.prenom}" }
      end
    end

    context "when the dossier is for a company" do
      let(:procedure) { create(:procedure, for_individual: false) }

      context "when the company is not provided" do
        let(:etablissement) { nil }
        it { is_expected.to be_blank }
      end

      context "when the company has name information" do
        it { is_expected.to eq raison_sociale_or_name(etablissement) }
      end
    end
  end

  describe ".dossier_submission_is_closed?" do
    let(:dossier) { create(:dossier, state: state) }
    let(:state) { Dossier.states.fetch(:brouillon) }

    subject { dossier_submission_is_closed?(dossier) }

    context "when dossier state is brouillon" do
      it { is_expected.to be false }

      context "when dossier state is brouillon and procedure is close" do
        before { dossier.procedure.close }

        it { is_expected.to be true }
      end
    end

    shared_examples_for "returns false" do
      it { is_expected.to be false }

      context "and procedure is close" do
        before { dossier.procedure.close }

        it { is_expected.to be false }
      end
    end

    context "when dossier state is en_construction" do
      let(:state) { Dossier.states.fetch(:en_construction) }

      it_behaves_like "returns false"
    end

    context "when dossier state is en_construction" do
      let(:state) { Dossier.states.fetch(:en_instruction) }

      it_behaves_like "returns false"
    end

    context "when dossier state is en_construction" do
      let(:state) { Dossier.states.fetch(:accepte) }

      it_behaves_like "returns false"
    end

    context "when dossier state is en_construction" do
      let(:state) { Dossier.states.fetch(:refuse) }

      it_behaves_like "returns false"
    end

    context "when dossier state is en_construction" do
      let(:state) { Dossier.states.fetch(:sans_suite) }

      it_behaves_like "returns false"
    end
  end

  describe '.dossier_display_state' do
    let(:dossier) { create(:dossier) }

    subject { dossier_display_state(dossier) }

    it 'brouillon is brouillon' do
      dossier.brouillon!
      expect(subject).to eq('Brouillon')
    end

    it 'en_construction is En construction' do
      dossier.en_construction!
      expect(subject).to eq('En construction')
    end

    it 'accepte is traité' do
      dossier.accepte!
      expect(subject).to eq('Accepté')
    end

    it 'en_instruction is reçu' do
      dossier.en_instruction!
      expect(subject).to eq('En instruction')
    end

    it 'sans_suite is traité' do
      dossier.sans_suite!
      expect(subject).to eq('Sans suite')
    end

    it 'refuse is traité' do
      dossier.refuse!
      expect(subject).to eq('Refusé')
    end

    context 'when requesting lowercase' do
      subject { dossier_display_state(dossier, lower: true) }

      it 'lowercases the display name' do
        dossier.brouillon!
        expect(subject).to eq('brouillon')
      end
    end

    context 'when providing directly a state name' do
      subject { dossier_display_state(:brouillon) }

      it 'generates a display name for the given state' do
        expect(subject).to eq('Brouillon')
      end
    end
  end

  describe '.dossier_legacy_state' do
    subject { dossier_legacy_state(dossier) }

    context 'when the dossier is en instruction' do
      let(:dossier) { create(:dossier) }

      it { is_expected.to eq('brouillon') }
    end

    context 'when the dossier is en instruction' do
      let(:dossier) { create(:dossier, :en_instruction) }

      it { is_expected.to eq('received') }
    end

    context 'when the dossier is accepte' do
      let(:dossier) { create(:dossier, state: Dossier.states.fetch(:accepte)) }

      it { is_expected.to eq('closed') }
    end

    context 'when the dossier is refuse' do
      let(:dossier) { create(:dossier, state: Dossier.states.fetch(:refuse)) }

      it { is_expected.to eq('refused') }
    end

    context 'when the dossier is sans_suite' do
      let(:dossier) { create(:dossier, state: Dossier.states.fetch(:sans_suite)) }

      it { is_expected.to eq('without_continuation') }
    end
  end

  describe '.has_lost_attachments' do
    let(:procedure) { create(:procedure, :published) }
    let(:dossier_with_lost_attachments)    { create(:dossier, procedure: procedure) }
    let(:dossier_without_lost_attachments) { create(:dossier, procedure: procedure) }

    before do
      expect(ENV).to receive(:[]).with('APP_HOST').at_least(:once).and_return(app_host)
      allow(helper).to receive(:dossiers_with_lost_attachments_ids).and_return([dossier_with_lost_attachments.id])
    end

    context 'on the DINUM instance' do
      let(:app_host) { 'demarches-simplifiees.fr' }

      it 'returns true for dossiers that lost attachments' do
        expect(helper.has_lost_attachments(dossier_with_lost_attachments)).to be(true)
        expect(helper.has_lost_attachments(dossier_without_lost_attachments)).to be(false)
      end
    end

    context 'on another instance' do
      let(:app_host) { 'polynesie-francaise.pref.gouv.fr' }

      it 'returns false for all dossiers' do
        expect(helper.has_lost_attachments(dossier_with_lost_attachments)).to be(false)
        expect(helper.has_lost_attachments(dossier_without_lost_attachments)).to be(false)
      end
    end
  end
end
