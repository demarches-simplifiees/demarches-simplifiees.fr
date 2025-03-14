# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250314updateProcedureClosedAtTask do
    describe "#process" do
      let(:closed_procedure) { create(:procedure, closed_at: Time.zone.parse('2025-02-25')) }

      setup do
        @task = T20250314updateProcedureClosedAtTask.new
        @task.procedure_id = closed_procedure.id
        @task.closing_date = '2025-02-27'
      end

      it "updates the procedure closed_at attribute" do
        expect { @task.process(closed_procedure) }.to change { closed_procedure.reload.closed_at }.from(Time.zone.parse('2025-02-25')).to(Time.zone.parse('2025-02-27'))
      end
    end
  end
end
