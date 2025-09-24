# frozen_string_literal: true

describe Champs::PoleEmploiChamp, type: :model do
  let(:champ) { described_class.new(dossier: build(:dossier)) }
  before { allow(champ).to receive(:type_de_champ).and_return(:type_de_champ_pole_emploi) }

  describe '#validate' do
    let(:validation_context) { :create }

    subject { champ.valid?(validation_context) }

    before do
      champ.identifiant = identifiant
    end

    context 'when identifiant is valid' do
      let(:identifiant) { 'georges_moustaki_77' }

      it { is_expected.to be true }
    end

    context 'when identifiant is nil' do
      let(:identifiant) { nil }

      it { is_expected.to be true }
    end
  end
end
