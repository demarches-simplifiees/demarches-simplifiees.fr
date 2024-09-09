# frozen_string_literal: true

describe Champs::DossierLinkChamp, type: :model do
  describe 'prefilling validations' do
    describe 'value' do
      subject { described_class.new(value:, dossier: build(:dossier)).valid?(:prefill) }

      context 'when nil' do
        let(:value) { nil }

        it { expect(subject).to eq(true) }
      end

      context 'when empty' do
        let(:value) { '' }

        it { expect(subject).to eq(true) }
      end

      context 'when an integer' do
        let(:value) { 42 }

        it { expect(subject).to eq(true) }
      end

      context 'when a string representing an integer' do
        let(:value) { "42" }

        it { expect(subject).to eq(true) }
      end

      context 'when it can be casted as integer' do
        let(:value) { 'totoro' }

        it { expect(subject).to eq(false) }
      end
    end
  end

  describe 'validation' do
    let(:champ) { Champs::DossierLinkChamp.new(value:, dossier: build(:dossier)) }

    before do
      allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_dossier_link, mandatory:))
      champ.run_callbacks(:validation)
    end

    subject { champ.validate(:champs_public_value) }

    context 'when not mandatory' do
      let(:mandatory) { false }
      let(:value) { nil }
      it { is_expected.to be_truthy }
    end

    context 'when mandatory' do
      let(:mandatory) { true }
      context 'when valid id' do
        let(:value) { create(:dossier).id }
        it { is_expected.to be_truthy }
      end

      context 'when invalid id' do
        let(:value) { 'kthxbye' }
        it { is_expected.to be_falsey }
      end
    end
  end
end
