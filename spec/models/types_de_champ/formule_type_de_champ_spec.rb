# frozen_string_literal: true

describe TypesDeChamp::FormuleTypeDeChamp do
  let(:type_de_champ) { build(:type_de_champ_formule, formule_expression: expression) }
  let(:formule_type_de_champ) { TypesDeChamp::FormuleTypeDeChamp.new(type_de_champ) }

  describe 'validation' do
    context 'with valid expression' do
      let(:expression) { '1 + 1' }

      it 'is valid' do
        expect(formule_type_de_champ).to be_valid
        expect(type_de_champ).to be_valid
      end
    end

    context 'with simple field reference' do
      let(:expression) { '{Montant HT} * 1.20' }

      it 'is valid' do
        expect(formule_type_de_champ).to be_valid
        expect(type_de_champ).to be_valid
      end
    end

    context 'with text formula' do
      let(:expression) { 'CONCAT({Prénom}, " ", {Nom})' }

      it 'is valid' do
        expect(formule_type_de_champ).to be_valid
        expect(type_de_champ).to be_valid
      end
    end

    context 'with too long expression' do
      let(:expression) { 'A' * 1001 }

      it 'is invalid' do
        formule_type_de_champ # trigger initialization
        expect(type_de_champ.errors[:formule_expression]).to be_present
      end
    end

    context 'with invalid field reference' do
      let(:expression) { '{}' }

      it 'is invalid' do
        formule_type_de_champ # trigger initialization
        expect(type_de_champ.errors[:formule_expression]).to be_present
      end
    end

    context 'with blank expression' do
      let(:expression) { '' }

      it 'is valid' do
        expect(formule_type_de_champ).to be_valid
        expect(type_de_champ).to be_valid
      end
    end
  end

  describe '#estimated_fill_duration' do
    let(:expression) { '1 + 1' }
    let(:revision) { build(:procedure_revision) }

    it 'returns 0 seconds as formule fields are not fillable' do
      expect(formule_type_de_champ.estimated_fill_duration(revision)).to eq(0.seconds)
    end
  end
end