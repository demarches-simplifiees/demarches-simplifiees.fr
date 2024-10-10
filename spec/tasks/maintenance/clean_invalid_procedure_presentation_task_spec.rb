# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe CleanInvalidProcedurePresentationTask do
    describe "#process" do
      subject(:process) { described_class.process(element) }
      let(:procedure) { create(:procedure) }
      let(:groupe_instructeur) { create(:groupe_instructeur, procedure:, instructeurs: [build(:instructeur)]) }
      let(:assign_to) { create(:assign_to, procedure:, instructeur: groupe_instructeur.instructeurs.first) }
      let(:element) { create(:procedure_presentation, procedure:, assign_to:) }

      before { element.update_column(:filters, filters) }

      context 'when filter is valid' do
        let(:filters) { { "suivis" => [{ 'table' => "self", 'column' => "id", "value" => (FilteredColumn::PG_INTEGER_MAX_VALUE - 1).to_s }] } }
        it 'keeps it filters' do
          expect { subject }.not_to change { element.reload.filters }
        end
      end

      context 'when filter is invalid, drop it' do
        let(:filters) { { "suivis" => [{ 'table' => "self", 'column' => "id", "value" => (FilteredColumn::PG_INTEGER_MAX_VALUE).to_s }] } }
        it 'drop invalid filters' do
          expect { subject }.to change { element.reload.filters }.to({ "suivis" => [] })
        end
      end
    end
  end
end
