# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20261013destroyOrphanStubEtablissementsTask do
    let(:stub) { create(:etablissement, dossier: nil, adresse: nil) }

    describe "#collection" do
      it "takes a stub without dossier" do
        expect(described_class.collection).to include(stub)
      end

      it "takes a stub whose dossier is gone" do
        stub.update_columns(dossier_id: 0)

        expect(described_class.collection).to include(stub)
      end

      it "leaves out a complete etablissement" do
        etablissement = create(:etablissement, dossier: nil)

        expect(described_class.collection).not_to include(etablissement)
      end

      it "leaves out a stub of a dossier" do
        dossier_stub = dossiers.entreprise_en_instruction.etablissement
        dossier_stub.update_columns(adresse: nil)

        expect(described_class.collection).not_to include(dossier_stub)
      end

      it "leaves out a stub tied to a champ" do
        dossiers.entreprise_en_instruction.champ_data.first.update_columns(etablissement_id: stub.id)

        expect(described_class.collection).not_to include(stub)
      end
    end

    describe "#process" do
      it "destroys the stub" do
        described_class.process(stub)

        expect(Etablissement.where(id: stub.id)).to be_empty
      end
    end
  end
end
