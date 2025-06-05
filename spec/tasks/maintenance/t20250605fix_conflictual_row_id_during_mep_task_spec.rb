# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250605fixConflictualRowIdDuringMepTask do
    describe "#process" do
      subject(:process) { described_class.process(dossier) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{}]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:type_de_champ) { dossier.revision.types_de_champ_public.first }

      before {
        dossier.champs.create(**type_de_champ.params_for_champ.merge(row_id: Champ::NULL_ROW_ID))
      }

      it { expect { subject }.not_to change { dossier.reload.updated_at } }
      it { expect { subject }.not_to change { dossier.champs.order(id: :desc).first.id } }
      it { expect { subject }.to change { dossier.champs.order(:id).first.id } }
      it { expect { subject }.to change { dossier.champs.count }.by(-1) }
      it { expect { subject }.to change { dossier.champs.where(row_id: Champ::NULL_ROW_ID).count }.from(1).to(0) }
    end
  end
end
