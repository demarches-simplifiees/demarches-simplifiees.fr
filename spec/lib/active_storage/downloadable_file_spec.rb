describe ActiveStorage::DownloadableFile do
  let(:dossier) { create(:dossier) }

  subject(:list) { ActiveStorage::DownloadableFile.create_list_from_dossier(dossier) }

  describe 'create_list_from_dossier' do
    context 'when no piece_justificative is present' do
      it { expect(list).to match([]) }
    end

    context 'when there is a piece_justificative' do
      before do
        dossier.champs << create(:champ, :piece_justificative, :with_piece_justificative_file)
      end

      it { expect(list.length).to be 1 }
    end
  end
end
