# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241216removeNonUniqueChampsTask do
    describe "#process" do
      subject(:process) { described_class.process(dossier) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{}]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:type_de_champ) { dossier.revision.types_de_champ_public.first }
      let(:champ_id) { dossier.champs.first.id }

      before {
        dossier.champs.create(**type_de_champ.params_for_champ)
      }

      it { expect { subject }.to change { dossier.reload.project_champ(type_de_champ).id }.from(dossier.champs.last.id).to(champ_id) }
      it { expect { subject }.to change { Champ.count }.by(-1) }
    end
  end
end