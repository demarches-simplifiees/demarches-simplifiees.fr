# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe DeleteOrphanedChampsWithMissingDossierTask do
    describe "#process" do
      let(:procedure) { create(:procedure, types_de_champ_public:) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:champ) { dossier.champs.first }

      subject(:process) { described_class.process(champ) }

      context 'with other champs' do
        let(:types_de_champ_public) { [{ type: :text }] }
        it 'delete champ' do
          expect { subject }.to change { Champ.exists?(champ.id) }.from(true).to(false)
        end
      end

      context "with carte" do
        let(:types_de_champ_public) { [{ type: :carte }] }
        it 'deletes champ.geo_areas' do
          geo_area_ids = champ.geo_areas.ids
          expect { subject }.to change { GeoArea.where(id: geo_area_ids).count }.from(2).to(0)
          expect(Champ.exists?(champ.id)).to be_falsey
        end
      end

      context "with repetition" do
        let(:types_de_champ_public) { [{ type: :repetition, mandatory: true, children: [{ type: :text }] }] }
        it 'deletes champ.champs (children)' do
          expect { subject }.to change { champ.champs.count }.from(2).to(0)
          expect(Champ.exists?(champ.id)).to be_falsey
        end
      end

      context "with siret" do
        let(:types_de_champ_public) { [{ type: :siret }] }
        it 'delete champ.etablissement' do
          expect { subject }.to change { Etablissement.exists?(champ.etablissement_id) }.from(true).to(false)
          expect(Champ.exists?(champ.id)).to be_falsey
        end
      end
    end
  end
end
