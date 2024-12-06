# frozen_string_literal: true

RSpec.describe Cron::PurgeOldBrouillonDossiersJob, type: :job do
  let(:procedure) { create(:procedure) }

  let!(:recent_brouillon) { travel_to(3.months.ago) { create(:dossier, :brouillon, procedure: procedure, notified_soon_deleted_sent_at: 3.weeks.ago) } }
  let!(:old_brouillon) { travel_to(5.months.ago) { create(:dossier, :brouillon, procedure: procedure, notified_soon_deleted_sent_at: 3.weeks.ago) } }
  let!(:very_old_brouillon) { travel_to(6.months.ago) { create(:dossier, :brouillon, procedure: procedure, notified_soon_deleted_sent_at: 3.weeks.ago) } }
  let!(:very_old_brouillon_but_not_notified) { travel_to(6.months.ago) { create(:dossier, :brouillon, procedure: procedure, notified_soon_deleted_sent_at: nil) } }
  let!(:old_en_construction) { travel_to(5.months.ago) { create(:dossier, :en_construction, procedure: procedure, notified_soon_deleted_sent_at: 3.weeks.ago) } }
  let!(:not_visible_dossier) { travel_to(6.months.ago) { create(:dossier, :brouillon, :hidden_by_user, procedure: procedure, notified_soon_deleted_sent_at: 3.weeks.ago) } }
  let!(:not_visible_dossier2) { travel_to(6.months.ago) { create(:dossier, :brouillon, :hidden_by_expired, procedure: procedure, notified_soon_deleted_sent_at: 3.weeks.ago) } }

  subject(:perform_job) { described_class.perform_now }

  describe '#perform' do
    before do
      allow(DossierMailer).to receive(:notify_old_brouillon_after_deletion).and_return(double(deliver_later: true))
    end

    it 'hides only old brouillon dossiers' do
      expect { perform_job }.to change { Dossier.visible_by_user.count }.by(-2)
    end

    it 'sends notification emails for each hidden dossier' do
      perform_job

      expect(DossierMailer).to have_received(:notify_old_brouillon_after_deletion).with(old_brouillon).once
      expect(DossierMailer).to have_received(:notify_old_brouillon_after_deletion).with(very_old_brouillon).once
      expect(DossierMailer).not_to have_received(:notify_old_brouillon_after_deletion).with(recent_brouillon)
      expect(DossierMailer).not_to have_received(:notify_old_brouillon_after_deletion).with(old_en_construction)
      expect(DossierMailer).not_to have_received(:notify_old_brouillon_after_deletion).with(not_visible_dossier)
      expect(DossierMailer).not_to have_received(:notify_old_brouillon_after_deletion).with(not_visible_dossier2)
    end

    it 'sets the correct hidden_by attributes' do
      perform_job

      [old_brouillon, very_old_brouillon].each do |dossier|
        dossier.reload
        expect(dossier.hidden_by_expired_at).to be_present
        expect(dossier.hidden_by_reason).to eq("not_modified_for_a_long_time")
      end
    end
  end
end
