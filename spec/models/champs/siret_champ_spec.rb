# frozen_string_literal: true

describe Champs::SiretChamp do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :siret }]) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first.tap { _1.update(value:, etablissement:) } }
  let(:value) { "" }
  let(:etablissement) { nil }

  describe '#validate' do
    subject { champ.tap { _1.validate(:champs_public_value) } }

    context 'when empty' do
      let(:value) { nil }

      it { is_expected.to be_valid }
    end

    context 'with invalid format' do
      let(:value) { "12345" }

      it { subject.errors[:value].should include('doit comporter exactement 14 chiffres') }
    end

    context 'with invalid checksum' do
      let(:value) { "12345678901234" }

      it { subject.errors[:value].should include("n‘est pas valide") }
    end

    context 'with valid format but no etablissement' do
      let(:value) { "12345678901245" }

      it { subject.errors[:value].should include("aucun établissement n’est rattaché à ce numéro") }
    end

    context 'with valid SIRET and etablissement' do
      let(:value) { "12345678901245" }
      let(:etablissement) { build(:etablissement, siret: value) }

      it { is_expected.to be_valid }
    end
  end
end
