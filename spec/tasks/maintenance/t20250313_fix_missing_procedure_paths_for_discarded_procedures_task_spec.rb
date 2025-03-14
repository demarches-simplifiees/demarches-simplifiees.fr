# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250313FixMissingProcedurePathsForDiscardedProceduresTask do
    let!(:procedure) { create(:procedure) }
    let!(:discarded_procedure) { create(:procedure, :discarded) }

    before do
      discarded_procedure.procedure_paths.delete_all
    end

    describe "#collection" do
      subject { described_class.new.collection }

      it "returns all discarded procedures without procedure_paths" do
        expect(subject).to contain_exactly(discarded_procedure)
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(element) }
      let(:element) {
        discarded_procedure
      }

      it "adds a procedure_path to the discarded procedure" do
        expect { process }.to change { discarded_procedure.procedure_paths.count }.from(0).to(1)
      end
    end
  end
end
