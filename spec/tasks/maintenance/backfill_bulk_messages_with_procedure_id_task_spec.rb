# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe BackfillBulkMessagesWithProcedureIdTask do
    describe "#process" do
      subject(:process) { described_class.process(bulk_message) }

      context 'with groupe instructeurs but no procedure_id' do
        let(:bulk_message) { create(:bulk_message) }
        let(:procedure) { bulk_message.groupe_instructeurs.first.procedure }

        before { bulk_message.update_column(:procedure_id, nil) }

        it 'fills procedure id' do
          subject
          expect(bulk_message.procedure_id).to eq procedure.id
        end
      end
    end
  end
end
