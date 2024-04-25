# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe BackfillClosingReasonInClosedProceduresTask do
    describe "#process" do
      subject(:process) { described_class.process(procedure) }

      context 'with a closed and replaced procedure' do
        let(:published_procedure) { create(:procedure, :published) }
        let(:procedure) { create(:procedure, :closed, replaced_by_procedure_id: published_procedure.id) }

        it 'fills closing_reason with internal_procedure' do
          subject
          expect(procedure.closing_reason).to eq Procedure.closing_reasons.fetch(:internal_procedure)
        end
      end

      context 'with a closed and not replaced procedure' do
        let(:procedure) { create(:procedure, :closed) }

        it 'fills closing_reason with other' do
          subject
          expect(procedure.closing_reason).to eq Procedure.closing_reasons.fetch(:other)
        end
      end
    end
  end
end
