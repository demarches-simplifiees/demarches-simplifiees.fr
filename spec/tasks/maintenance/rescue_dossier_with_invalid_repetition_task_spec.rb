# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe RescueDossierWithInvalidRepetitionTask do
    describe "#process" do
      let(:procedure) { create(:procedure, types_de_champ_public:) }
      let(:types_de_champ_public) do
        [
          { type: :repetition, children: [{ type: :text, mandatory: true }] },
          { type: :checkbox }
        ]
      end
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:invalid_champ) { dossier.champs.find(&:checkbox?) }

      # reproduce bad data
      before { invalid_champ.update!(row_id: dossier.champs[1].row_id) }

      it "dissociate champ having a row_id without a parent_id" do
        expect { described_class.process(dossier) }
          .to change { Champ.exists?(invalid_champ.id) }.from(true).to(false)
      end
    end
  end
end
