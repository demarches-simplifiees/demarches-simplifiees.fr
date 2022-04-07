describe ActiveStorage::DownloadableFile do
  let(:dossier) { create(:dossier, :en_construction) }

  subject(:list) { ActiveStorage::DownloadableFile.create_list_from_dossiers(Dossier.where(id: dossier.id)) }

  describe 'create_list_from_dossiers' do
    context 'when no piece_justificative is present' do
      it { expect(list.length).to eq 1 }
      it { expect(list.first[0].name).to eq "pdf_export_for_instructeur" }
    end
  end
end
