# frozen_string_literal: true

describe Champs::SiretChamp do
  let(:champ) { Champs::SiretChamp.new(value: "", dossier: build(:dossier)) }
  before do
    allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_siret))
    allow(champ).to receive(:in_dossier_revision?).and_return(true)
  end

  def with_value(value)
    champ.tap { _1.value = value }
  end

  describe '#validate' do
    subject { champ.tap { _1.validate(:champs_public_value) } }

    context 'when empty' do
      it { expect(with_value(nil)).to be_valid }
    end

    context 'with invalid format' do
      before { with_value('12345') }

      it { subject.errors[:value].should include('doit comporter exactement 14 chiffres') }
    end

    context 'with invalid checksum' do
      before { with_value('12345678901234') }

      it { subject.errors[:value].should include("n‘est pas valide") }
    end

    context 'with valid format but no etablissement' do
      before { with_value('12345678901245') }

      it { subject.errors[:value].should include("aucun établissement n’est rattaché à ce numéro") }
    end

    context 'with valid SIRET and etablissement' do
      before do
        with_value('12345678901245')
        champ.etablissement = build(:etablissement, siret: champ.value)
      end

      it { is_expected.to be_valid }
    end
  end
end
