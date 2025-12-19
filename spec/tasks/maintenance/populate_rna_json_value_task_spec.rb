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
            "title" => "LA PRÉVENTION ROUTIERE",
            "city_code" => "75108",
            "city_name" => "Paris",
            "postal_code" => "75009",
            "region_code" => nil,
            "region_name" => nil,
            "street_name" => "de Modagor",
            "country_code" => "FR",
            "country_name" => "France",
            "street_number" => "33",
            "street_address" => "33 rue de Modagor",
            "association_rna" => "W751080001",
            "department_code" => nil,
            "department_name" => nil,
            "departement_code" => nil,
            "departement_name" => nil,
            "association_objet" =>
            "L'association a pour objet de promouvoir la pratique du sport de haut niveau et de contribuer à la formation des jeunes sportifs.",
            "association_date_creation" => "2015-01-01",
            "association_date_declaration" => "2019-01-01",
            "association_date_publication" => "2018-01-01",
          })
      end
    end
  end
end
