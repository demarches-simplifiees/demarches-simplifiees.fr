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
        dossier.champs.create(**repetition.params_for_champ, row_id: Champ::NULL_ROW_ID)
        dossier.reload
      }

      it { expect { subject }.not_to change { dossier.reload.updated_at } }
      it { expect { subject }.to change { dossier.champs.count }.by(-3) }
    end

    describe "create rows" do
      subject(:process) { described_class.process(dossier) }
      let(:procedure) do
        create(:procedure,
          types_de_champ_public: [{ type: :repetition, stable_id: 99, children: [{}, {}] }, { type: :repetition, children: [{}] }],
          types_de_champ_private: [{ type: :repetition, children: [{}] }])
      end
      let(:dossier) { create(:dossier, :with_populated_champs, :with_populated_annotations, procedure:) }

      before {
        repetition_1_rows, repetition_2_rows = dossier.champs.filter(&:public?).filter(&:row?).partition { _1.stable_id == 99 }
        repetition_1_rows.each(&:destroy!)
        repetition_2_rows.first.discard!
        dossier.champs.filter(&:private?).find(&:row?).destroy!
        dossier.reload
      }

      it { expect { subject }.not_to change { dossier.reload.updated_at } }
      it { expect { subject }.to change { dossier.champs.where(type: 'Champs::RepetitionChamp').count }.from(3).to(6) }
    end
  end
end
