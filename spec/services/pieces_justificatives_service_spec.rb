describe PiecesJustificativesService do
  let(:procedure) { create(:procedure, :with_titre_identite) }
  let(:dossier) { create(:dossier, procedure: procedure) }
  let(:champ_identite) { dossier.champs.find { |c| c.type == 'Champs::TitreIdentiteChamp' } }
  let(:bill_signature) do
    bs = build(:bill_signature, :with_serialized, :with_signature)
    bs.save(validate: false)
    bs
  end

  before do
    champ_identite
      .piece_justificative_file
      .attach(io: StringIO.new("toto"), filename: "toto.png", content_type: "image/png")
    create(:dossier_operation_log, dossier: dossier, bill_signature: bill_signature)
  end

  describe '.liste_documents' do
    subject { PiecesJustificativesService.liste_documents(Dossier.where(id: dossier.id), false) }

    it "doesn't return sensitive documents like titre_identite" do
      expect(champ_identite.piece_justificative_file).to be_attached
      expect(subject.any? { |piece, _| piece.name == 'piece_justificative_file' }).to be_falsy
    end

    it "returns operation logs of the dossier" do
      expect(subject.any? { |piece, _| piece.name == 'serialized' }).to be_truthy
    end
  end

  describe '.generate_dossier_export' do
    subject { PiecesJustificativesService.generate_dossier_export(dossier) }
    it "generates pdf export for instructeur" do
      subject
    end

    it "doesn't update dossier" do
      before_export = Time.zone.now
      subject
      expect(dossier.updated_at).to be <= before_export
    end
  end
end
