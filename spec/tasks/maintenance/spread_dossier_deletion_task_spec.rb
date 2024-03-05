# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe SpreadDossierDeletionTask do
    describe "#process" do
      let(:dossiers) { Dossier.all }
      before do
        create(:dossier, termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_AT + 1.hour)
        create(:dossier, termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_AT + 2.hours)
        create(:dossier, termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_AT + 3.hours)
        create(:dossier, termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_AT + 4.hours)
      end
      subject(:process) { described_class.process(dossiers) }

      it "works" do
        expect { subject }.to change { Dossier.where(termine_close_to_expiration_notice_sent_at: Maintenance::SpreadDossierDeletionTask::ERROR_OCCURED_RANGE).count }
          .from(4).to(0)
      end
    end
  end
end
