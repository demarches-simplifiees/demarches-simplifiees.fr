# frozen_string_literal: true

describe ActiveStorage::DownloadableFile do
  let(:dossier) { dossiers.en_construction }
  let(:user_profile) { administrateurs.default }
  subject(:list) { ActiveStorage::DownloadableFile.create_list_from_dossiers(user_profile:, dossiers: Dossier.where(id: dossier.id)) }

  describe 'create_list_from_dossiers' do
    context 'when no piece_justificative is present' do
      it do
        expect(list.length).to eq 1
        expect(list.first[0].name).to eq "pdf_export_for_instructeur"
      end
    end
  end
end
