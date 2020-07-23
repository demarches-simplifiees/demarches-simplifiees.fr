RSpec.describe TmpDossiersMigrateRevisionsJob, type: :job do
  let(:procedure) { create(:procedure, :published) }
  let!(:dossier1) { create(:dossier, procedure: procedure, updated_at: 1.day.ago) }
  let!(:dossier2) { create(:dossier, procedure: procedure, updated_at: 2.days.ago) }

  context "add revision to dossiers" do
    before do
      RevisionsMigration.add_revisions(procedure)
    end

    it {
      expect(dossier1.revision).to be_nil
      expect(dossier2.revision).to be_nil

      TmpDossiersMigrateRevisionsJob.new.perform([])
      [dossier1, dossier2].each(&:reload)

      expect(dossier1.revision).to eq procedure.active_revision
      expect(dossier2.revision).to eq procedure.active_revision
      expect(dossier1.updated_at < 1.day.ago).to be_truthy
      expect(dossier2.updated_at < 1.day.ago).to be_truthy
    }
  end
end
