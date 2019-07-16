describe ActiveStorage::DownloadableFile do
  let(:tpjs) { [tpj_not_mandatory] }
  let!(:tpj_not_mandatory) do
    TypeDePieceJustificative.create(libelle: 'not mandatory', mandatory: false)
  end
  let(:procedure) { Procedure.create(types_de_piece_justificative: tpjs) }
  let(:dossier) { Dossier.create(procedure: procedure) }
  let(:procedure) { Procedure.create(types_de_piece_justificative: tpjs) }
  let(:dossier) { Dossier.create(procedure: procedure) }
  let(:list) { ActiveStorage::DownloadableFile.create_list_from_dossier(dossier) }

  describe 'create_list_from_dossier' do
    context 'when no piece_justificative is present' do
      it { expect(list).to match([]) }
    end

    context 'when there is a piece_justificative' do
      let (:pj) { create(:champ, :piece_justificative, :with_piece_justificative_file) }
      before do
        dossier.champs = [pj]
      end

      it { expect(list.length).to be 1 }
    end
  end
end
