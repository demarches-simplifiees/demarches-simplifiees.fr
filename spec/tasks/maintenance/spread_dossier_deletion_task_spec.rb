# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe SpreadDossierDeletionTask do
    describe "#process" do
      let(:dossiers) { Dossier.all }
      let(:dossier_1) { create(:dossier, termine_close_to_expiration_notice_sent_at: Date.new(2024, 2, 14)) }
      let(:dossier_2) { create(:dossier, termine_close_to_expiration_notice_sent_at: Date.new(2024, 2, 14)) }
      let(:dossier_3) { create(:dossier, termine_close_to_expiration_notice_sent_at: Date.new(2024, 2, 14)) }
      let(:dossier_4) { create(:dossier, termine_close_to_expiration_notice_sent_at: Date.new(2024, 2, 14)) }
      subject(:process) { described_class.process(dossiers) }

      it "works" do
        expect { subject }.to change { dossier_1.reload.termine_close_to_expiration_notice_sent_at }
      end
    end
  end
end
