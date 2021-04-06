describe ActiveStorage::DownloadableFile do
  let(:dossier) { create(:dossier, :en_construction, :with_pdf_export) }

  subject(:list) { ActiveStorage::DownloadableFile.create_list_from_dossier(dossier) }

  describe 'create_list_from_dossier' do
    context 'when no piece_justificative is present' do
      it { expect(list.length).to eq 1 }
      it { expect(list.first[0].record_type).to eq "Dossier" }
    end

    context 'when there is a piece_justificative' do
      before do
        dossier.champs << create(:champ_piece_justificative, :with_piece_justificative_file, dossier: dossier)
      end

      it { expect(list.length).to eq 2 }
    end

    context 'when there is a private piece_justificative' do
      before do
        dossier.champs_private << create(:champ_piece_justificative, :with_piece_justificative_file, private: true, dossier: dossier)
      end

      it { expect(list.length).to eq 2 }
    end

    context 'when there is a repetition bloc' do
      before do
        dossier.champs << create(:champ_repetition_with_piece_jointe, dossier: dossier)
      end

      it 'should have 4 piece_justificatives' do
        expect(list.size).to eq 5
      end
    end

    context 'when there is a message with no attachment' do
      before do
        dossier.commentaires << create(:commentaire, dossier: dossier)
      end

      it { expect(list.length).to eq 1 }
    end

    context 'when there is a message with an attachment' do
      before do
        dossier.commentaires << create(:commentaire, :with_file, dossier: dossier)
      end

      it { expect(list.length).to eq 2 }
    end
  end
end
