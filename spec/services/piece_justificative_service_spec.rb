describe PiecesJustificativesService do
  let(:dossier) { create(:dossier, :en_construction) }

  describe 'zip_entries' do
    let(:list) { PiecesJustificativesService.zip_entries(dossier) }
    let(:names) { list.map { |pair| pair[1].to_s } }

    context 'when no piece_justificative is present' do
      it { expect(list).to match([]) }
    end

    context 'dossier with champ' do
      before do
        dossier.champs << champ
      end

      context 'piece_justificative with file' do
        let(:champ) { create(:champ_piece_justificative, :with_piece_justificative_file) }
        it { expect(names).to eq [champ_libelle(champ)] }
      end

      context 'piece_justificative without file' do
        let(:champ) { create(:champ_piece_justificative_empty) }
        it { expect(names).to eq [] }
      end

      context 'private piece_justificative with file' do
        let(:champ) { create(:champ_piece_justificative, :with_piece_justificative_file, private: true) }
        it { expect(names).to eq [champ_libelle(champ)] }
      end
    end

    context 'when there is a repetition bloc' do
      let(:repetition) { build(:champ_repetition_with_piece_jointe) }
      let(:dossier) { create(:dossier, :en_construction, champs: [repetition]) }

      it 'should have 4 piece_justificatives' do
        expect(names).to eq([
          champ_libelle(repetition.champs[0]),
          champ_libelle(repetition.champs[1]),
          champ_libelle(repetition.champs[2]).sub(/\./, '-2.'),
          champ_libelle(repetition.champs[3]).sub(/\./, '-2.')
        ])
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

      it { expect(names).to eq [message_libelle(commentaire)] }
    end

    context 'when there multiple messages with same file' do
      let(:commentaire1) { create(:commentaire, :with_file, dossier: dossier) }
      let(:commentaire2) { create(:commentaire, :with_file, dossier: dossier) }
      before do
        dossier.commentaires << commentaire1 << commentaire2
      end

      it {
        expect(names).to eq([
          message_libelle(commentaire1),
          message_libelle(commentaire2).sub(/\./, '-2.')
        ])
      }
    end

    def champ_libelle(champ)
      "pieces_justificatives/" + PiecesJustificativesService.pieces_justificative_filename(champ)
    end

    def message_libelle(pj)
      'messagerie/' + pj.piece_jointe.filename.to_s
    end
  end
end
