require 'spec_helper'

describe PiecesJustificativesService do
  let(:user) { create(:user) }
  let(:safe_file) { true }

  before :each do
    allow(ClamavService).to receive(:safe_file?).and_return(safe_file)
  end

  describe 'self.upload!' do
    let(:hash) { {} }
    let!(:tpj_not_mandatory) do
      TypeDePieceJustificative.create(libelle: 'not mandatory', mandatory: false)
    end
    let!(:tpj_mandatory) do
      TypeDePieceJustificative.create(libelle: 'justificatif', mandatory: true)
    end
    let(:procedure) { Procedure.create(types_de_piece_justificative: tpjs) }
    let(:dossier) { Dossier.create(procedure: procedure) }
    let(:errors) { PiecesJustificativesService.upload!(dossier, user, hash) }

    context 'when no piece justificative is required' do
      let(:tpjs) { [tpj_not_mandatory] }

      context 'when no params are given' do
        it { expect(errors).to eq([]) }
      end

      context 'when sometihing wrong with file save' do
        let(:hash) do
          {
            "piece_justificative_#{tpj_not_mandatory.id}" =>
              double(path: '', original_filename: 'file')
          }
        end

        it { expect(errors).to match(["le fichier not mandatory n'a pas pu être sauvegardé"]) }
      end

      context 'when a virus is provided' do
        let(:safe_file) { false }
        let(:hash) do
          {
            "piece_justificative_#{tpj_not_mandatory.id}" =>
              double(path: '', original_filename: 'bad_file')
          }
        end

        it { expect(errors).to match(['bad_file: <b>Virus détecté !!</b>']) }
      end
    end

    context 'when a piece justificative is required' do
      let(:tpjs) { [tpj_mandatory] }

      context 'when no params are given' do
        it { expect(errors).to match(['La pièce jointe justificatif doit être fournie.']) }
      end

      context 'when the piece justificative is provided' do
        before :each do
          # we are messing around piece_justificative
          # because directly doubling carrierwave params seems complicated

          allow(PiecesJustificativesService).to receive(:save_pj).and_return('')
          piece_justificative_double = double(type_de_piece_justificative: tpj_mandatory)
          expect(dossier).to receive(:pieces_justificatives).and_return([piece_justificative_double])
        end

        let(:hash) do
          {
            "piece_justificative_#{tpj_mandatory.id}" => double(path: '')
          }
        end

        it { expect(errors).to match([]) }
      end
    end
  end
end
