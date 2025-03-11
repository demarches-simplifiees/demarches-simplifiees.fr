# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250219MigratePathRewriteToProcedurePathsTask do
    describe "#process" do
      subject(:process) { described_class.process(path_rewrite) }

      let(:administrateur) { create(:administrateur) }
      let(:path_rewrite) { create(:path_rewrite, from: "source-path", to: "destination-path") }

      context "when destination procedure exists" do
        let!(:destination_procedure) { create(:procedure, path: "destination-path", administrateurs: [administrateur]) }

        it "adds the source path to the destination procedure" do
          expect { process }.to change {
            destination_procedure.reload.procedure_paths.where(path: "source-path").count
          }.from(0).to(1)
        end

        it "maintains the original canonical path" do
          original_canonical_path = destination_procedure.canonical_path
          process
          expect(destination_procedure.reload.canonical_path).to eq(original_canonical_path)
        end
      end

      context "when destination procedure does not exist" do
        it "skips processing and logs a message" do
          expect(Procedure).to receive(:find_with_path).with(path_rewrite.to).and_return([])
          expect(Rails.logger).to receive(:info).with(/Destination procedure not found/)

          process
        end
      end

      context "when source and destination paths already link to the same procedure" do
        let!(:destination_procedure) { create(:procedure, path: "destination-path", administrateurs: [administrateur]) }

        before do
          destination_procedure.claim_path!(administrateur, "source-path")
        end

        it "skips processing and logs a message" do
          expect(Rails.logger).to receive(:info).with(/Destination procedure is the same as the source procedure/)

          expect { process }.not_to change { ProcedurePath.count }
        end
      end
    end

    describe "#collection" do
      subject { described_class.new.collection }

      before do
        create_list(:path_rewrite, 3)
      end

      it "returns all PathRewrite records" do
        expect(subject.count).to eq(3)
        expect(subject).to all(be_a(PathRewrite))
      end
    end
  end
end
