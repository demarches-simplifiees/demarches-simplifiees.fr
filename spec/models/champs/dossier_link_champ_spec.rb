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
end
