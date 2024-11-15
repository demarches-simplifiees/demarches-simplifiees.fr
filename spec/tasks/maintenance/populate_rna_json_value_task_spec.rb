# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe PopulateRNAJSONValueTask do
    describe "#process" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :rna }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:element) { dossier.champs.first }
      subject(:process) { described_class.process(element) }

      let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }
      let(:status) { 200 }

      before do
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/djepva\/api-association\/associations\/open_data\/#{element.value}/)
          .to_return(body: body, status: status)
        allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      end
      it 'updates value_json' do
        expect { subject }.to change { element.reload.value_json }
          .from(anything)
          .to({
            "street_number" => "33",
            "street_name" => "de Modagor",
            "street_address" => "33 rue de Modagor",
            "postal_code" => "75009",
            "city_name" => "Paris",
            "city_code" => "75108",
            "departement_code" => nil,
            "department_code" => nil,
            "departement_name" => nil,
            "department_name" => nil,
            "region_code" => nil,
            "region_name" => nil,
            "title" => "LA PRÉVENTION ROUTIERE"
          })
      end
    end
  end
end
