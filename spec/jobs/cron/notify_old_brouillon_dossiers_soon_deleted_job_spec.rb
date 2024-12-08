# frozen_string_literal: true

RSpec.describe Cron::NotifyOldBrouillonDossiersSoonDeletedJob, type: :job do
  describe "#perform" do
    let(:job) { described_class.new }

    context "when there are old draft dossiers" do
      let!(:old_draft_never_notified) { travel_to(4.months.ago) { create(:dossier, :brouillon) } }
      let!(:old_draft_notified_before_update) do
        travel_to(4.months.ago) do
          create(:dossier, :brouillon, notified_soon_deleted_sent_at: 1.month.ago)
        end
      end
      let!(:old_draft_recently_notified) do
        travel_to(4.months.ago) do
          create(:dossier, :brouillon, notified_soon_deleted_sent_at: 3.months.from_now)
        end
      end
      let!(:recent_draft) { travel_to(2.months.ago) { create(:dossier, :brouillon) } }
      let!(:old_non_draft) { travel_to(4.months.ago) { create(:dossier, :en_construction) } }
      let!(:not_visible_dossier) { travel_to(6.months.ago) { create(:dossier, :brouillon, :hidden_by_user) } }
      let!(:not_visible_dossier2) { travel_to(6.months.ago) { create(:dossier, :brouillon, :hidden_by_expired) } }

      it "sends notifications only for eligible draft dossiers" do
        expect(DossierMailer).to receive(:notify_old_brouillon_soon_deleted)
          .with(old_draft_never_notified)
          .and_return(double(deliver_later: true))
          .once

        expect(DossierMailer).to receive(:notify_old_brouillon_soon_deleted)
          .with(old_draft_notified_before_update)
          .and_return(double(deliver_later: true))
          .once

        [old_draft_recently_notified, not_visible_dossier, not_visible_dossier2].each do |dossier|
          expect(DossierMailer).not_to receive(:notify_old_brouillon_soon_deleted)
            .with(dossier)
        end

        job.perform

        expect(old_draft_never_notified.reload.notified_soon_deleted_sent_at).to be_present
        expect(old_draft_notified_before_update.reload.notified_soon_deleted_sent_at).to be_present
      end
    end

    context "when there are no old draft dossiers" do
      let!(:recent_draft) { create(:dossier, :brouillon, updated_at: 2.months.ago) }

      it "doesn't send any notifications" do
        expect(DossierMailer).not_to receive(:notify_old_brouillon_soon_deleted)

        job.perform
      end
    end
  end
end
