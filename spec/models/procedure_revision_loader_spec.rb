describe ProcedureRevisionPreloader do
  let(:procedure) do
    create(:procedure, :published,
           types_de_champ_public: [
             { type: :integer_number },
             { type: :decimal_number }
           ],
           types_de_champ_private: [
             { type: :text },
             { type: :textarea }
           ])
  end

  describe '.load_one' do
    let(:revision) { procedure.draft_revision }
    subject { ProcedureRevisionPreloader.load_one(revision) }

    it 'assigns stuffs correctly' do
      original_procedure = Procedure.find(procedure.id)
      expect(procedure.draft_revision.association(:revision_types_de_champ).loaded?).to be_falsy
      expect(procedure.draft_revision.association(:revision_types_de_champ_public).loaded?).to be_falsy
      expect(procedure.draft_revision.association(:revision_types_de_champ_private).loaded?).to be_falsy
      expect(procedure.draft_revision.association(:types_de_champ).loaded?).to be_falsy
      expect(procedure.draft_revision.association(:types_de_champ_public).loaded?).to be_falsy
      expect(procedure.draft_revision.association(:types_de_champ_private).loaded?).to be_falsy
      subject
      expect(procedure.draft_revision.association(:revision_types_de_champ).loaded?).to be_truthy
      expect(procedure.draft_revision.association(:revision_types_de_champ_public).loaded?).to be_truthy
      expect(procedure.draft_revision.association(:revision_types_de_champ_private).loaded?).to be_truthy
      expect(procedure.draft_revision.association(:types_de_champ).loaded?).to be_truthy
      expect(procedure.draft_revision.association(:types_de_champ_public).loaded?).to be_truthy
      expect(procedure.draft_revision.association(:types_de_champ_private).loaded?).to be_truthy

      expect(revision.revision_types_de_champ.first.association(:revision).loaded?).to eq(true)
      expect(revision.revision_types_de_champ.first.association(:procedure).loaded?).to eq(true)
    end
  end
end
