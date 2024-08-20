# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe PopulateSiretValueJSONTask do
    describe "#process" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :siret }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:element) { dossier.champs.first }
      subject(:process) { described_class.process(element) }

      it 'updates value_json' do
        expect { subject }.to change { element.reload.value_json }
          .from(nil)
          .to({
            "city_code" => "92009",
            "city_name" => "Bois-Colombes",
            "postal_code" => "92270",
            "region_code" => "11",
            "region_name" => "Île-de-France",
            "street_name" => "RAOUL NORDLING",
            "street_number" => "6",
            "street_address" => "6 RUE RAOUL NORDLING",
            "departement_code" => "92",
            "departement_name" => "Hauts-de-Seine"
          })
      end
    end
  end
end
