# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250526NullifyRowIdTask do
    describe "#process" do
      subject(:process) { described_class.process }
      let(:procedure) { create(:procedure, types_de_champ_public: [{}, { type: :repetition, children: [{ type: :text }] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:champs_with_null_row_id) { dossier.champs.where(row_id: [nil, Champ::NULL_ROW_ID]) }

      before do
        dossier.champs.where(row_id: nil).update_all(row_id: Champ::NULL_ROW_ID)
      end

      def null_row_id_counts
        champs_with_null_row_id.pluck(:row_id)
          .partition(&:nil?)
          .map(&:size)
      end

      it 'nullify row_id' do
        expect { process }. to change { null_row_id_counts }.from([0, 1]).to([1, 0])
      end
    end
  end
end
