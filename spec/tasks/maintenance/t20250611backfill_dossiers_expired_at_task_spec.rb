# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250611backfillDossiersExpiredAtTask do
    describe "#process" do
      subject(:process) { described_class.process(dossier) }

      context "when dossier is en brouillon" do
        let(:dossier) { create(:dossier, :brouillon) }
        before { dossier.update_column(:expired_at, nil) }

        it "updates dossier expired_at attribute" do
          expect { process }.to change { dossier.reload.expired_at }.from(nil).to be_within(1.second).of(dossier.expiration_date)
        end
      end

      context "when dossier is en construction" do
        let(:dossier) { create(:dossier, :en_construction) }
        before { dossier.update_column(:expired_at, nil) }

        it "updates dossier expired_at attribute" do
          expect { process }.to change { dossier.reload.expired_at }.from(nil).to be_within(1.second).of(dossier.expiration_date)
        end
      end

      context "when dossier is en instruction" do
        let(:dossier) { create(:dossier, :en_instruction) }
        it "raises an error" do
          expect { process }.to raise_error(RuntimeError, 'expiration_date_reference should not be called in state en_instruction')
        end
      end
    end
  end
end
