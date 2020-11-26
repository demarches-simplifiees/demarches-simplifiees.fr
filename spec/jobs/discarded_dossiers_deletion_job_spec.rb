RSpec.describe DiscardedDossiersDeletionJob, type: :job do
  include ActiveJob::TestHelper

  let(:instructeur) { create(:instructeur) }
  let!(:dossier_brouillon) { create(:dossier) }
  let!(:dossier) { create(:dossier, :en_construction) }

  let!(:discarded_dossier_brouillon) { create(:dossier, hidden_at: 2.weeks.ago) }
  let!(:discarded_dossier_en_construction) { create(:dossier, :en_construction, hidden_at: 2.weeks.ago) }
  let!(:discarded_dossier_termine) { create(:dossier, :accepte, hidden_at: 2.weeks.ago) }
  let!(:discarded_dossier_termine_today) { create(:dossier, :accepte, hidden_at: 1.hour.ago) }

  before do
    discarded_dossier_en_construction.send(:log_dossier_operation, instructeur, :passer_en_instruction, discarded_dossier_en_construction)
    discarded_dossier_termine.send(:log_dossier_operation, instructeur, :passer_en_instruction, discarded_dossier_termine)
    discarded_dossier_termine_today.send(:log_dossier_operation, instructeur, :passer_en_instruction, discarded_dossier_termine_today)

    discarded_dossier_en_construction.send(:log_dossier_operation, instructeur, :supprimer, discarded_dossier_en_construction)
    discarded_dossier_termine.send(:log_dossier_operation, instructeur, :supprimer, discarded_dossier_termine)
    discarded_dossier_termine_today.send(:log_dossier_operation, instructeur, :supprimer, discarded_dossier_termine_today)
  end

  context 'cleanup discared dossiers' do
    it 'delete dossiers and operation logs' do
      expect(Dossier.with_discarded.count).to eq(6)
      expect(DossierOperationLog.count).to eq(6)

      DiscardedDossiersDeletionJob.perform_now

      expect(Dossier.with_discarded.count).to eq(3)
      expect(DossierOperationLog.count).to eq(4)
    end
  end
end
