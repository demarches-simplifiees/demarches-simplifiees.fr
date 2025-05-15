describe InitiationProcedureConcern do
  describe '.create_initiation_procedure' do
    let(:administrateur) { administrateurs(:default_admin) }
    subject { Procedure.create_initiation_procedure(administrateur) }

    it "returns a new procedure" do
      subject
      subject.reload
      expect(subject).to be_valid
      expect(subject.defaut_groupe_instructeur.instructeurs.count).to eq(1)
      expect(subject.draft_revision.types_de_champ_public).not_to be_empty
      expect(subject.service).not_to be_nil
    end
  end
end
