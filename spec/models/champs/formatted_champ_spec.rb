# frozen_string_literal: true

describe Champs::FormattedChamp do
  describe 'validation' do
    let(:champ) do
      described_class.new(dossier: build(:dossier), value:)
    end

    before do
      allow(champ).to receive(:type_de_champ).and_return(type_de_champ)
      allow(champ).to receive(:in_dossier_revision?).and_return(true)
    end

    subject { champ.validate(:champs_public_value) }

    context 'with simple mode' do
      let(:type_de_champ) { build(:type_de_champ_formatted, :numbers_accepted) }

      let(:value) { "coucou" }

      it { is_expected.to be_falsey }
    end
  end
end
