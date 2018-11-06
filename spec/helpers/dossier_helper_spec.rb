require 'rails_helper'

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

  describe ".dossier_submission_is_closed?" do
    let(:dossier) { create(:dossier, state: state) }
    let(:state) { Dossier.states.fetch(:brouillon) }

    subject { dossier_submission_is_closed?(dossier) }

    context "when dossier state is brouillon" do
      it { is_expected.to be false }

      context "when dossier state is brouillon and procedure is archivee" do
        before { dossier.procedure.archive }

        it { is_expected.to be true }
      end
    end

    shared_examples_for "returns false" do
      it { is_expected.to be false }

      context "and procedure is archivee" do
        before { dossier.procedure.archive }

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

    context "lower: true" do
      subject { dossier_display_state(dossier, lower: true) }

      it 'brouillon is brouillon' do
        dossier.brouillon!
        expect(subject).to eq('brouillon')
      end

      it 'en_construction is En construction' do
        dossier.en_construction!
        expect(subject).to eq('en construction')
      end

      it 'accepte is traité' do
        dossier.accepte!
        expect(subject).to eq('accepté')
      end

      it 'en_instruction is reçu' do
        dossier.en_instruction!
        expect(subject).to eq('en instruction')
      end

      it 'sans_suite is traité' do
        dossier.sans_suite!
        expect(subject).to eq('sans suite')
      end

      it 'refuse is traité' do
        dossier.refuse!
        expect(subject).to eq('refusé')
      end
    end
  end
end
