describe ActiveStorage::DownloadableFile do
  let(:dossier) { create(:dossier, :en_construction) }

  subject(:list) { ActiveStorage::DownloadableFile.create_list_from_dossiers(Dossier.where(id: dossier.id)) }

  describe 'create_list_from_dossiers' do
    context 'when no piece_justificative is present' do
      it { expect(list.length).to eq 1 }
      it { expect(list.first[0].name).to eq "pdf_export_for_instructeur" }
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

    context 'when the files are asked by an expert with piece justificative and private piece justificative' do
      let(:expert) { create(:expert) }
      let(:instructeur) { create(:instructeur) }
      let(:procedure) { create(:procedure, :published, :with_piece_justificative, instructeurs: [instructeur]) }
      let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: procedure) }
      let(:dossier) { create(:dossier, :en_construction, :with_dossier_link, procedure: procedure) }
      let(:champ) { dossier.champs.first }
      let(:avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure, confidentiel: true) }

      subject(:list) { ActiveStorage::DownloadableFile.create_list_from_dossiers(Dossier.where(id: dossier.id), true) }

      before do
        dossier.champs_private << create(:champ_piece_justificative, :with_piece_justificative_file, private: true, dossier: dossier)

        dossier.champs << create(:champ_piece_justificative, :with_piece_justificative_file, dossier: dossier)
      end

      it { expect(list.length).to eq 2 }
    end
  end
end
