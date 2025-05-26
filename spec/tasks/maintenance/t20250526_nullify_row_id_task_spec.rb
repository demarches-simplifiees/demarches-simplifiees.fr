# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250526NullifyRowIdTask do
    describe "#process" do
      subject(:process) { described_class.process(element) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{}, { type: :repetition, children: [{ type: :text }] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }

      before do
        dossier.champs.where(row_id: nil).update_all(row_id: Champ::NULL_ROW_ID)
      end

      it 'nullify row_id' do
        expect(dossier.champs.where(row_id: nil).count).to eq(0)
        expect(dossier.champs.where(row_id: Champ::NULL_ROW_ID).count).to eq(1)
        described_class.process
        expect(dossier.champs.where(row_id: nil).count).to eq(1)
        expect(dossier.champs.where(row_id: Champ::NULL_ROW_ID).count).to eq(0)
      end
    end
  end
end
