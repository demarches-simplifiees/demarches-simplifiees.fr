# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241202migrateNonFillableAndRepetitionChampsTask do
    describe "remove header_section, explication and repetition" do
      subject(:process) { described_class.process(dossier) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :header_section }, { type: :explication }, {}, { type: :repetition, children: [{}] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }

      before {
        header_section, explication, _, repetition = dossier.revision.types_de_champ_public
        dossier.champs.create(**header_section.params_for_champ)
        dossier.champs.create(**explication.params_for_champ)
        dossier.champs.create(**repetition.params_for_champ)
        dossier.reload
      }

      it { expect { subject }.not_to change { dossier.reload.updated_at } }
      it { expect { subject }.to change { dossier.champs.count }.by(-3) }
    end

    describe "create rows" do
      subject(:process) { described_class.process(dossier) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{}] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }

      before {
        dossier.champs.filter(&:row?).each(&:destroy!)
        dossier.reload
      }

      it { expect { subject }.not_to change { dossier.reload.updated_at } }
      it { expect { subject }.to change { dossier.champs.where(type: 'Champs::RepetitionChamp').count }.by(2) }
    end
  end
end
