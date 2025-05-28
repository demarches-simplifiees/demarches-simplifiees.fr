# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250527dropInvalideGeoAreasTask do
    describe "#process" do
      subject(:process) { described_class.process(element) }
      let(:procedure) { create(:procedure, types_de_champ_public:) }
      let(:types_de_champ_public) { [{ type: :carte }] }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:champ) { dossier.champs.first }

      context "with a valid geo_area (point)" do
        let!(:geo_area) { create(:geo_area, :point, champ:) }
        let(:element) { geo_area }
        it "does not destroy the geo_area" do
          expect { process }.not_to change { GeoArea.exists?(geo_area.id) }.from(true)
        end
      end

      context "with an invalid geo_area (invalid_point)" do
        let!(:geo_area) { create(:geo_area, :point, champ:) }
        let(:invalid_geometry) { build(:geo_area, :invalid_point).geometry }
        before { geo_area.update_column(:geometry, invalid_geometry) }
        let(:element) { geo_area }
        it "destroys the geo_area" do
          expect { process }.to change { GeoArea.exists?(geo_area.id) }.from(true).to(false)
        end
      end
    end
  end
end
