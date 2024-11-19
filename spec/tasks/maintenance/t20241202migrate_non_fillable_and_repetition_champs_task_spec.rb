# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241202migrateNonFillableAndRepetitionChampsTask do
    describe "#process" do
      subject(:process) { described_class.process(dossier) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :header_section }, { type: :explication }, {}, { type: :repetition, children: [{}] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }

      before {
        header_section, explication, _, repetition = dossier.revision.types_de_champ_public
        dossier.champs.create(**header_section.params_for_champ)
        dossier.champs.create(**explication.params_for_champ)
        dossier.champs.create(**repetition.params_for_champ)
      }

      it { expect { subject }.to change { Champ.count }.by(-3) }
    end
  end
end
