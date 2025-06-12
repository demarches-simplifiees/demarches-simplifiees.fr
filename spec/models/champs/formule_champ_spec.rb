# frozen_string_literal: true

describe Champs::FormuleChamp do
  let(:type_de_champ) { build(:type_de_champ_formule, formule_expression: expression) }
  let(:champ) { Champs::FormuleChamp.new(dossier: build(:dossier)) }

  before do
    allow(champ).to receive(:type_de_champ).and_return(type_de_champ)
  end

  describe '#value' do
    context 'with simple expression' do
      let(:expression) { '1 + 1' }

      it 'returns the computed value' do
        expect(champ.value).to eq('1 + 1')
      end
    end

    context 'with field references' do
      let(:expression) { '{Montant HT} * 1.20' }

      it 'returns information about field references' do
        expect(champ.value).to include('1 field(s) referenced')
      end
    end

    context 'with text formula' do
      let(:expression) { 'CONCAT({Prénom}, " ", {Nom})' }

      it 'returns information about field references' do
        expect(champ.value).to include('2 field(s) referenced')
      end
    end

    context 'with blank expression' do
      let(:expression) { '' }

      it 'returns empty string' do
        expect(champ.value).to eq('')
      end
    end

    context 'with nil expression' do
      let(:expression) { nil }

      it 'returns empty string' do
        expect(champ.value).to eq('')
      end
    end
  end

  describe '#blank?' do
    context 'with computed value' do
      let(:expression) { '1 + 1' }

      it 'is not blank' do
        expect(champ).not_to be_blank
      end
    end

    context 'with no expression' do
      let(:expression) { '' }

      it 'is blank' do
        expect(champ).to be_blank
      end
    end
  end

  describe '#for_export' do
    let(:expression) { '1 + 1' }

    it 'returns the computed value' do
      expect(champ.for_export).to eq(champ.value)
    end
  end

  describe '#for_api' do
    let(:expression) { '1 + 1' }

    it 'returns the computed value' do
      expect(champ.for_api).to eq(champ.value)
    end
  end

  describe '#for_api_v2' do
    let(:expression) { '1 + 1' }

    it 'returns the computed value' do
      expect(champ.for_api_v2).to eq(champ.value)
    end
  end

  describe '#search_terms' do
    let(:expression) { 'Résultat test' }

    it 'returns an array with the computed value' do
      expect(champ.search_terms).to eq([champ.value])
    end
  end

  describe '#to_s' do
    let(:expression) { '1 + 1' }

    it 'returns the computed value as string' do
      expect(champ.to_s).to eq(champ.value.to_s)
    end
  end

  describe 'validation' do
    let(:test_champ) { Champs::FormuleChamp.new(dossier: build(:dossier), computed_value: computed_value) }

    before do
      allow(test_champ).to receive(:type_de_champ).and_return(type_de_champ)
    end

    context 'with expression and computed value' do
      let(:expression) { '1 + 1' }
      let(:computed_value) { 'result' }

      it 'is valid' do
        expect(test_champ).to be_valid
      end
    end

    context 'with expression but no computed value' do
      let(:expression) { '1 + 1' }
      let(:computed_value) { nil }

      it 'is invalid' do
        expect(test_champ).not_to be_valid
        expect(test_champ.errors[:computed_value]).to include("doit être rempli")
      end
    end

    context 'with no expression' do
      let(:expression) { '' }
      let(:computed_value) { nil }

      it 'is valid' do
        expect(test_champ).to be_valid
      end
    end
  end

  describe 'before_save callback' do
    let(:expression) { '2 + 2' }

    it 'has the callback defined' do
      expect(Champs::FormuleChamp._save_callbacks.map(&:filter)).to include(:compute_value)
    end
  end
end