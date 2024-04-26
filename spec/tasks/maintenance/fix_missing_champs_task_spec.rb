# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe FixMissingChampsTask do
    describe "#process" do
      subject(:process) { described_class.process(dossiers) }
      let(:procedure) { create(:procedure, types_de_champ_public:) }
      let(:types_de_champ_public) { [{ type: :text, libelle: 'l1' }, { type: :text, libelle: 'l2' }] }
      let(:dossier_1) { create(:dossier, procedure:) }
      let(:dossiers) { [dossier_1] }
      it "add missing champs" do
        dossier_1.champs.last.destroy
        expect { subject }.to change { dossier_1.champs.count }.by(1)
      end
    end
  end
end
