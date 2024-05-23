# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe UpdateClosingReasonIfNoReplacedByIdTask do
    describe "#process" do
      subject(:process) { described_class.process(procedure) }

      let(:procedure) { create(:procedure, :closed) }

      before do
        procedure.update_column(:closing_reason, Procedure.closing_reasons.fetch(:internal_procedure))
        procedure.update_column(:replaced_by_procedure_id, nil)
      end

      it 'updates closing_reason to other' do
        subject
        expect(procedure.closing_reason).to eq(Procedure.closing_reasons.fetch(:other))
      end
    end
  end
end
