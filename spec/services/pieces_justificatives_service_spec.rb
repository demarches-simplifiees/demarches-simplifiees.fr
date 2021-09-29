describe PiecesJustificativesService do
  describe '.liste_pieces_justificatives' do
    let(:procedure) { create(:procedure, :with_titre_identite) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:champ_identite) { dossier.champs.find { |c| c.type == 'Champs::TitreIdentiteChamp' } }

    before do
      champ_identite
        .piece_justificative_file
        .attach(io: StringIO.new("toto"), filename: "toto.png", content_type: "image/png")
    end

    subject { PiecesJustificativesService.liste_pieces_justificatives(dossier) }

    # titre identite is too sensitive
    # to be exported
    it 'ensures no titre identite is given' do
      expect(champ_identite.piece_justificative_file).to be_attached
      expect(subject).to eq([])
    end
  end
end
