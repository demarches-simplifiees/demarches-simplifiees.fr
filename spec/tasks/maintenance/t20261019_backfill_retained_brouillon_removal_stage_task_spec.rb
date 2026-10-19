# frozen_string_literal: true

require "rails_helper"

module Maintenance
  describe T20261019BackfillRetainedBrouillonRemovalStageTask do
    let(:notice_period) { Expired::REMAINING_WEEKS_BEFORE_EXPIRATION.weeks }
    let(:expired_at) { Time.zone.parse('2026-12-01 22:00') }

    # Rows written by the previous code: without the stage.
    def written_before_deploy(dossier, **columns)
      dossier.tap { it.update_columns(removal_stage: nil, removal_due_at: nil, expired_at:, **columns) }
    end

    def backfilled_ids
      described_class.collection.flat_map(&:ids)
    end

    describe '#collection' do
      it 'selects the brouillons out of the trash and never warned whose stage or notice date disagrees only' do
        legacy = written_before_deploy(dossiers.brouillon)
        moved = create(:dossier, :brouillon).tap { it.update_columns(expired_at:) }
        retained = create(:dossier, :brouillon)
        warned = create(:dossier, :brouillon).tap { it.update!(brouillon_close_to_expiration_notice_sent_at: Time.current) }
        trashed = create(:dossier, :brouillon).tap { it.hide_and_keep_track!(it.user, :user_request) }
        en_construction = written_before_deploy(dossiers.en_construction)

        expect(backfilled_ids).to include(legacy.id, moved.id)
        expect(backfilled_ids).not_to include(retained.id, warned.id, trashed.id, en_construction.id)
      end
    end

    describe '#process' do
      def process(dossier)
        described_class.process(Dossier.where(id: dossier))
        dossier.reload
      end

      it 'dates the notice a notice period before the expiration' do
        brouillon = written_before_deploy(dossiers.brouillon)

        expect(process(brouillon)).to have_attributes(removal_stage: 'retained', removal_due_at: expired_at - notice_period)
        expect(brouillon.removal_notice_at).to eq(brouillon.removal_due_at)
      end

      # Like removal_notice_at: 14 days in Paris time, 337 hours across the switch to winter time.
      it 'counts the notice period in Paris time across a change of daylight saving time' do
        brouillon = written_before_deploy(dossiers.brouillon, expired_at: Time.zone.parse('2026-11-03 22:00'))

        expect(process(brouillon).removal_due_at).to eq(Time.zone.parse('2026-10-20 22:00'))
        expect(brouillon.removal_notice_at).to eq(brouillon.removal_due_at)
      end
    end
  end
end
