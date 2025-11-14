# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251105BackfillProConnectRestrictionTask do
    let(:task) { described_class.new }

    describe "#collection" do
      it "returns procedures with pro_connect_restricted=true and pro_connect_restriction=:none" do
        procedure_to_backfill = create(:procedure, pro_connect_restricted: true, pro_connect_restriction: :none)
        create(:procedure, pro_connect_restricted: true, pro_connect_restriction: :instructeurs)
        create(:procedure, pro_connect_restricted: false, pro_connect_restriction: :none)

        expect(task.collection).to contain_exactly(procedure_to_backfill)
      end
    end

    describe "#process" do
      it "updates pro_connect_restriction to :instructeurs" do
        procedure = create(:procedure, pro_connect_restricted: true, pro_connect_restriction: :none)

        task.process(procedure)

        expect(procedure.reload).to be_pro_connect_restriction_instructeurs
      end
    end
  end
end
