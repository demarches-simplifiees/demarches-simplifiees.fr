# frozen_string_literal: true

describe Champs::CommuneChamp do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :communes, stable_id: 99 }]) }
  let(:dossier) { create(:dossier, procedure:) }

  let(:code_insee) { '63102' }
  let(:code_postal) { '63290' }
  let(:code_departement) { '63' }
  let(:champ) do
    described_class.new(stable_id: 99, dossier:).tap do |champ|
      champ.code_postal = code_postal
      champ.external_id = code_insee
      champ.run_callbacks(:save)
    end
  end

  describe 'value' do
    it 'find commune' do
      expect(champ.to_s).to eq('Châteldon (63290)')
      expect(champ.name).to eq('Châteldon')
      expect(champ.external_id).to eq(code_insee)
      expect(champ.code).to eq(code_insee)
      expect(champ.code_departement).to eq(code_departement)
      expect(champ.code_postal).to eq(code_postal)
      expect(champ.for_export(:value)).to eq 'Châteldon (63290)'
      expect(champ.for_export(:code)).to eq '63102'
      expect(champ.for_export(:departement)).to eq '63 – Puy-de-Dôme'
    end

    context 'with tricky bug (should not happen, but it happens)' do
      let(:champ) do
        described_class.new(stable_id: 99, dossier:).tap do |champ|
          champ.external_id = ''
          champ.value = 'Gagny'
          champ.run_callbacks(:save)
        end
      end

      it 'fails' do
        expect(champ).to receive(:instrument_external_id_error)
        expect(champ.validate(:champs_public_value)).to be_falsey
        expect(champ.errors).to include('external_id')
      end
    end

    context 'with code' do
      let(:champ) do
        described_class.new(stable_id: 99, dossier:).tap do |champ|
          champ.code = '63102-63290'
          champ.run_callbacks(:save)
        end
      end

      it 'find commune' do
        expect(champ.to_s).to eq('Châteldon (63290)')
        expect(champ.name).to eq('Châteldon')
        expect(champ.external_id).to eq(code_insee)
        expect(champ.code).to eq(code_insee)
        expect(champ.code_departement).to eq(code_departement)
        expect(champ.code_postal).to eq(code_postal)
        expect(champ.for_export(:value)).to eq 'Châteldon (63290)'
        expect(champ.for_export(:code)).to eq '63102'
        expect(champ.for_export(:departement)).to eq '63 – Puy-de-Dôme'
      end
    end
  end
end
