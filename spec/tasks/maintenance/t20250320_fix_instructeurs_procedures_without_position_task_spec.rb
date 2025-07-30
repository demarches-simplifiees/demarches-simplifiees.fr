# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250320FixInstructeursProceduresWithoutPositionTask do
    # we finally added a not null constraint on position in #11876
    before do
      ActiveRecord::Base.connection.execute("ALTER TABLE instructeurs_procedures ALTER COLUMN position DROP NOT NULL;")
    end

    describe "#process" do
      subject(:process) { described_class.process(element) }

      let(:element) { create(:instructeurs_procedure, position: nil) }

      it "updates the instructeur_procedure position to 99" do
        expect { process }.to change { element.reload.position }.from(nil).to(99)
      end
    end

    describe "#collection" do
      subject { described_class.new.collection }

      before do
        create_list(:instructeurs_procedure, 2, position: nil)
        create(:instructeurs_procedure, position: 1)
        create(:instructeurs_procedure, position: 2)
      end

      it "returns only instructeur_procedures with nil position" do
        expect(subject.count).to eq(2)
      end
    end
  end
end
