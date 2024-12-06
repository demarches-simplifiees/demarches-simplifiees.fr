# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe MigrateExistingProcedurePathsTask do
    describe "#process" do
      subject(:process) { described_class.process(element) }

      context "when procedure is published" do
        let(:element) { create(:procedure, :published) }

        before do
          element.update_column("path", "path-not-in-procedure-paths")
          element.procedure_paths.delete_all
        end

        it "should use the same generated path as procedure_path" do
          expect { process }.to change { element.procedure_paths.count }.from(0).to(1)
          expect(element.procedure_paths.last.path).to eq("path-not-in-procedure-paths")
        end

        context "when procedure is already migrated" do
          before do
            create(:procedure_path, procedure: element, path: "path-not-in-procedure-paths")
          end

          it "should not generate any new ProcedurePath" do
            expect { process }.not_to change { ProcedurePath.count }
          end
        end
      end

      context "when procedure is not published" do
        let(:element) { create(:procedure, :closed) }

        before do
          element.update_column("path", "some-path")
          element.procedure_paths.delete_all
        end

        context "when path is already used by another published procedure" do
          let(:other_procedure) { create(:procedure, :published) }

          before do
            other_procedure.update_column("path", "some-path")
          end

          it "should generate a new UUID path" do
            expect { process }.to change { element.procedure_paths.count }.from(0).to(1)
            expect(element.procedure_paths.last.path).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
          end

          context "when other_procedure is already migrated" do
            before do
              create(:procedure_path, procedure: other_procedure, path: "some-path")
            end

            it "should generate a new UUID path" do
              expect { process }.to change { element.procedure_paths.count }.from(0).to(1)
              expect(element.procedure_paths.last.path).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
            end
          end
        end

        context "when path is not used by another published procedure" do
          it "should use the same path" do
            expect { process }.to change { element.procedure_paths.count }.from(0).to(1)
            expect(element.procedure_paths.last.path).to eq("some-path")
          end
        end
      end
    end
  end
end
