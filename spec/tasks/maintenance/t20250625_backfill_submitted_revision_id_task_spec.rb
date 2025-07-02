# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250625BackfillSubmittedRevisionIdTask do
    describe "#process" do
      subject(:process) { described_class.process(dossier) }
      let(:dossier) { create(:dossier, :en_construction) }

      it {
        dossier.update_column(:submitted_revision_id, nil)
        expect(dossier.traitements.first.revision_id).to eq(dossier.revision_id)

        process

        expect(dossier.submitted_revision_id).not_to be_nil
      }
    end
  end
end
