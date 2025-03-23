# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe CreateProcedureTagsTask do
    describe "#process" do
      subject(:process) { described_class.new.process(tag) }

      let(:tag) { "Accompagnement" }
      let!(:procedure) { create(:procedure) }

      before do
        # Insertion directe du tag dans la base de données
        ActiveRecord::Base.connection.execute(
          "UPDATE procedures SET tags = ARRAY['#{tag}'] WHERE id = #{procedure.id}"
        )
      end

      it "creates the ProcedureTag if it does not exist" do
        expect { process }.to change { ProcedureTag.count }.by(1)
        expect(ProcedureTag.last.name).to eq(tag)
      end

      context "when the ProcedureTag already exists" do
        let!(:procedure_tag) { ProcedureTag.create(name: tag) }

        it "does not create a duplicate ProcedureTag" do
          expect { process }.not_to change { ProcedureTag.count }
        end
      end

      it "associates procedures with the ProcedureTag" do
        process
        expect(procedure.reload.procedure_tags.map(&:name)).to include(tag)
      end
    end
  end
end
