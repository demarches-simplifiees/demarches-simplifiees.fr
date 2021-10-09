describe PiecesJustificativesService do
  describe 'zip_entries' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:list) { PiecesJustificativesService.zip_entries(dossier) }
    let(:names) { list.map { |pair| pair[1].to_s } }

    context 'dossier without piece_justificative' do
      it { expect(names).to match([dossier_libelle(dossier)]) }
    end

    context 'dossier with piece justificative' do
      let(:dossier) { champ.dossier }
      before do
        dossier.champs << champ
      end

      context 'dossier with champ' do
        context 'piece_justificative with file' do
          let(:champ) { create(:champ_piece_justificative, :with_piece_justificative_file) }
          it { expect(names).to eq [dossier_libelle(dossier), champ_libelle(champ)] }
        end

        context 'piece_justificative without file' do
          let(:champ) { create(:champ_piece_justificative_empty) }
          it { expect(names).to eq [dossier_libelle(dossier)] }
        end

        context 'private piece_justificative with file' do
          let(:champ) { create(:champ_piece_justificative, :with_piece_justificative_file, private: true) }
          it { expect(names).to eq [dossier_libelle(dossier), champ_libelle(champ)] }
        end
      end

      context 'when there is a repetition bloc' do
        let(:champ) { create(:champ_repetition_with_piece_jointe) }

        it 'should have 4 piece_justificatives' do
          expect(names).to eq([
            dossier_libelle(dossier),
            champ_libelle(champ.champs[0]),
            champ_libelle(champ.champs[1]),
            champ_libelle(champ.champs[2]).sub(/\./, '-2.'),
            champ_libelle(champ.champs[3]).sub(/\./, '-2.')
          ])
        end
      end
    end

    context 'with commentaires' do
      let(:dossier) { create(:dossier, :en_construction) }
      before do
        dossier.commentaires.concat(commentaires)
      end

      context 'when there is a message with no attachment' do
        let(:commentaires) { [create(:commentaire, dossier: dossier)] }

        it { expect(list.length).to eq 1 }
      end

      context 'when there is a message with an attachment' do
        let(:commentaires) { [create(:commentaire, :with_file, dossier: dossier)] }

        it { expect(names).to eq [dossier_libelle(dossier), message_libelle(commentaires[0])] }
      end

      context 'when there multiple messages with same file' do
        let(:commentaire1) { create(:commentaire, :with_file, dossier: dossier) }
        let(:commentaire2) { create(:commentaire, :with_file, dossier: dossier) }
        let(:commentaires) { [commentaire1, commentaire2] }

        it {
          expect(names).to eq([
            dossier_libelle(dossier),
            message_libelle(commentaire1),
            message_libelle(commentaire2).sub(/\./, '-2.')
          ])
        }
      end
    end

    def champ_libelle(champ)
      "pieces_justificatives/" + PiecesJustificativesService.pieces_justificative_filename(champ)
    end

    def message_libelle(pj)
      'messagerie/' + pj.piece_jointe.filename.to_s
    end

    def dossier_libelle(dossier)
      "export-#{dossier.id}.pdf"
    end
  end
end
