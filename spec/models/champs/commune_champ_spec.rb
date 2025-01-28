# frozen_string_literal: true

describe Champs::CommuneChamp do
  let(:types_de_champ_public) { [{ type: :communes }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first }

  let(:code_insee) { '63102' }
  let(:code_postal) { '63290' }
  let(:code_departement) { '63' }

  describe 'value' do
    context 'default' do
      before do
        champ.code_postal = code_postal
        champ.external_id = code_insee
        champ.save
      end

      it 'find commune' do
        expect(champ.to_s).to eq('Châteldon (63290)')
        expect(champ.name).to eq('Châteldon')
        expect(champ.external_id).to eq(code_insee)
        expect(champ.code).to eq(code_insee)
        expect(champ.code_departement).to eq(code_departement)
        expect(champ.code_postal).to eq(code_postal)
        expect(champ.type_de_champ.champ_value_for_export(champ, :value)).to eq 'Châteldon (63290)'
        expect(champ.type_de_champ.champ_value_for_export(champ, :code)).to eq '63102'
        expect(champ.type_de_champ.champ_value_for_export(champ, :departement)).to eq '63 – Puy-de-Dôme'
      end
    end

    context 'with tricky bug (should not happen, but it happens)' do
      before do
        champ.external_id = ''
        champ.value = 'Gagny'
        champ.save
      end

      it 'fails' do
        expect(champ).to receive(:instrument_external_id_error)
        expect(champ.validate(:champs_public_value)).to be_falsey
        expect(champ.errors).to include('external_id')
      end
    end

    context 'with code' do
      before do
        champ.code = '63102-63290'
        champ.save
      end

      it 'find commune' do
        expect(champ.to_s).to eq('Châteldon (63290)')
        expect(champ.name).to eq('Châteldon')
        expect(champ.external_id).to eq(code_insee)
        expect(champ.code).to eq(code_insee)
        expect(champ.code_departement).to eq(code_departement)
        expect(champ.code_postal).to eq(code_postal)
        expect(champ.type_de_champ.champ_value_for_export(champ, :value)).to eq 'Châteldon (63290)'
        expect(champ.type_de_champ.champ_value_for_export(champ, :code)).to eq '63102'
        expect(champ.type_de_champ.champ_value_for_export(champ, :departement)).to eq '63 – Puy-de-Dôme'
      end
    end
  end
end
