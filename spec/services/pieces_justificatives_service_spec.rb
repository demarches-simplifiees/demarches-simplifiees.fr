require 'spec_helper'

describe PiecesJustificativesService do
  let(:user) { create(:user) }
  let(:safe_file) { true }

  before :each do
    allow(ClamavService).to receive(:safe_file?).and_return(safe_file)
  end

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
  let(:tpjs) { [tpj_not_mandatory] }

  describe 'self.upload!' do
    context 'when no params are given' do
      it { expect(errors).to eq([]) }
    end

    context 'when there is something wrong with file save' do
      let(:hash) do
        {
          "piece_justificative_#{tpj_not_mandatory.id}" =>
            double(path: '', original_filename: 'filename')
        }
      end

      it { expect(errors).to match(["le fichier filename (not mandatory) n'a pas pu être sauvegardé"]) }
    end

    context 'when a virus is provided' do
      let(:safe_file) { false }
      let(:hash) do
        {
          "piece_justificative_#{tpj_not_mandatory.id}" =>
            double(path: '', original_filename: 'bad_file')
        }
      end

      it { expect(errors).to match(['bad_file : virus détecté']) }
    end

    context 'when a regular file is provided' do
      let(:content) { double(path: '', original_filename: 'filename') }
      let(:hash) do
        {
          "piece_justificative_#{tpj_not_mandatory.id}" =>
            content
        }
      end

      before :each do
        expect(PiecesJustificativesService).to receive(:save_pj)
          .with(content, dossier, tpj_not_mandatory, user)
          .and_return(nil)
      end

      it 'is saved' do
        expect(errors).to match([])
      end
    end
  end

  describe 'missing_pj_error_messages' do
    let(:errors) { PiecesJustificativesService.missing_pj_error_messages(dossier) }
    let(:tpjs) { [tpj_mandatory] }

    context 'when no params are given' do
      it { expect(errors).to match(['La pièce jointe justificatif doit être fournie.']) }
    end

    context 'when the piece justificative is provided' do
      before :each do
        # we are messing around piece_justificative
        # because directly doubling carrierwave params seems complicated

        piece_justificative_double = double(type_de_piece_justificative: tpj_mandatory)
        expect(dossier).to receive(:pieces_justificatives).and_return([piece_justificative_double])
      end

      it { expect(errors).to match([]) }
    end
  end

  describe 'types_pj_as_types_de_champ' do
    subject { PiecesJustificativesService.types_pj_as_types_de_champ(procedure) }

    it 'generates one header champ, plus one champ per PJ' do
      expect(subject.pluck(:libelle)).to contain_exactly("Pièces jointes", "not mandatory")
    end

    it 'remembers the id of the PJ that got converted into a champ' do
      expect(subject.map(&:old_pj)).to include({ 'stable_id' => tpj_not_mandatory.id })
    end

    context 'without pre-existing champs' do
      it 'generates a sequence of order_places incrementing from zero' do
        expect(subject.pluck(:order_place)).to contain_exactly(0, 1)
      end
    end

    context 'with pre-existing champs' do
      let(:procedure) do
        create(
          :procedure,
          types_de_piece_justificative: tpjs,
          types_de_champ: [build(:type_de_champ, order_place: 0), build(:type_de_champ, order_place: 1)]
        )
      end

      it 'generates a sequence of incrementing order_places that continues where the last type de champ left off' do
        expect(subject.pluck(:order_place)).to contain_exactly(2, 3)
      end
    end

    context 'with pre-existing champs without an order place' do
      let(:procedure) do
        create(
          :procedure,
          types_de_piece_justificative: tpjs,
          types_de_champ: [build(:type_de_champ, order_place: 0), build(:type_de_champ, order_place: nil)]
        )
      end

      it 'ignores champs without an order place' do
        expect(subject.pluck(:order_place)).to contain_exactly(1, 2)
      end
    end
  end
end
