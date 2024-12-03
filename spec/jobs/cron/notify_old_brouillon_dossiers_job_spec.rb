# frozen_string_literal: true

RSpec.describe Cron::NotifyOldBrouillonDossiersSoonDeletedJob, type: :job do
  let(:procedure) { create(:procedure) }

  let!(:recent_brouillon) { create(:dossier, :brouillon, procedure: procedure, updated_at: 2.months.ago) }
  let!(:old_brouillon) { create(:dossier, :brouillon, procedure: procedure, updated_at: 4.months.ago) }
  let!(:old_en_construction) { create(:dossier, :en_construction, procedure: procedure, updated_at: 4.months.ago) }

  subject(:perform_job) { described_class.perform_now }

  describe '#perform' do
    before do
      allow(DossierMailer).to receive(:notify_old_brouillon_soon_deleted).and_return(double(deliver_later: true))
      perform_job
    end

    it 'sends email only for old brouillon dossiers' do
      expect(DossierMailer).to have_received(:notify_old_brouillon_soon_deleted).with(old_brouillon).once
      expect(DossierMailer).not_to have_received(:notify_old_brouillon_soon_deleted).with(recent_brouillon)
      expect(DossierMailer).not_to have_received(:notify_old_brouillon_soon_deleted).with(old_en_construction)
    end
  end
end
