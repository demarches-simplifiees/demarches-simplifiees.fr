# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250106FixClosedProceduresReplacedBySelfTask do
    let!(:replacement_procedure) { create(:procedure, :published) }

    # Procedures that should be fixed
    let!(:closed_procedure_to_fix) { create(:procedure, :closed) }
    let!(:discarded_closed_procedure_to_fix) { create(:procedure, :closed, :discarded) }

    # Procedures that should NOT be fixed
    let!(:closed_procedure_with_valid_replacement) { create(:procedure, :closed, replaced_by_procedure: replacement_procedure) }
    let!(:closed_procedure_with_nil_replacement) { create(:procedure, :closed, replaced_by_procedure_id: nil) }

    before do
      # Set up circular references for procedures that should be fixed
      # We use update_column to bypass validations that prevent this scenario
      closed_procedure_to_fix.update_columns(
        closing_reason: Procedure.closing_reasons.fetch(:internal_procedure),
        replaced_by_procedure_id: closed_procedure_to_fix.id
      )
      discarded_closed_procedure_to_fix.update_columns(
        closing_reason: Procedure.closing_reasons.fetch(:internal_procedure),
        replaced_by_procedure_id: discarded_closed_procedure_to_fix.id
      )

      # Run the task
      described_class.collection.find_each do |procedure|
        described_class.process(procedure)
      end
    end

    it "fixes closed procedures with circular references and leaves others unchanged" do
      # Procedures that should be fixed
      closed_procedure_to_fix.reload
      expect(closed_procedure_to_fix.closing_reason).to eq(Procedure.closing_reasons.fetch(:other))
      expect(closed_procedure_to_fix.replaced_by_procedure_id).to be_nil

      discarded_closed_procedure_to_fix.reload
      expect(discarded_closed_procedure_to_fix.closing_reason).to eq(Procedure.closing_reasons.fetch(:other))
      expect(discarded_closed_procedure_to_fix.replaced_by_procedure_id).to be_nil

      # Procedures that should NOT be changed
      closed_procedure_with_valid_replacement.reload
      expect(closed_procedure_with_valid_replacement.replaced_by_procedure_id).to eq(replacement_procedure.id)

      closed_procedure_with_nil_replacement.reload
      expect(closed_procedure_with_nil_replacement.replaced_by_procedure_id).to be_nil
    end
  end
end
