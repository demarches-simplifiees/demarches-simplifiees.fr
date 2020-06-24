describe ActiveStorage::DownloadableFile do
  let(:procedure) { create(:procedure, :with_instructeur) }
  let(:dossier) { create(:dossier, procedure: procedure) }
  let(:requesting_account) { { user: dossier.user } }

  subject(:list) { ActiveStorage::DownloadableFile.create_list_from_dossier(dossier, requesting_account) }

  describe 'create_list_from_dossier' do
    context 'when no piece_justificative is present' do
      it { expect(list).to match([]) }
    end

    context 'when there is a piece_justificative' do
      before do
        dossier.champs << create(:champ, :piece_justificative, :with_piece_justificative_file)
      end

      it { expect(list.length).to eq 1 }
    end

    context 'when there is a private piece_justificative' do
      before do
        dossier.champs_private << create(:champ, :piece_justificative, :with_piece_justificative_file, private: true)
      end

      context 'when the requesting user is allowed to see private annotations' do
        let(:instructeur) { procedure.instructeurs.first }
        let(:requesting_account) { { user: instructeur.user, instructeur: instructeur } }

        it { expect(list.length).to eq 1 }
      end

      context 'when the requesting user can’t see private annotations' do
        let(:requesting_account) { { user: dossier.user } }

        it { expect(list.length).to eq 0 }
      end
    end

    context 'when there is a repetition bloc' do
      let(:champ) { build(:champ_repetition_with_piece_jointe) }
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure, champs: [champ]) }

      it 'should have 4 piece_justificatives' do
        expect(list.size).to eq 4
      end
    end

    context 'when there is a message with no attachment' do
      let(:commentaire) { create(:commentaire) }
      let(:dossier) { commentaire.dossier }

      it { expect(list.length).to eq 0 }
    end

    context 'when there is a message with an attachment' do
      let(:commentaire) { create(:commentaire, :with_file) }
      let(:dossier) { commentaire.dossier }

      it { expect(list.length).to eq 1 }
    end
  end
end
