# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe MigrateExistingProcedurePathsTask do
    describe "#process" do
      subject(:process) { described_class.process(element) }

      context "when procedure has no explicit procedure path" do
        let(:element) {
          create(:procedure)
        }

        before do
          # destroy the procedure path created by the after_save hook
          element.procedure_paths.delete_all
        end

        it "should use the same generated path as procedure_path" do
          expect { process }.to change { element.procedure_paths.count }.from(0).to(1)
          expect(element.path).to eq(element.procedure_paths.last.path)
        end
      end
    end
  end
end
