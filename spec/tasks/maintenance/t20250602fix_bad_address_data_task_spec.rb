# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250602fixBadAddressDataTask do
    describe "#process" do
      subject(:process) { described_class.process(address_champ) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :address }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:address_champ) { dossier.champs.first }

      context "when the address is a partial address with international data" do
        let(:value_json) do
          {
            "not_in_ban" => "true",
            "country_code" => "CH",
            "street_address" => "128 rue brancion, paris 75015"
          }
        end
        before { address_champ.update_columns(value: "123 Main St", value_json:) }

        it do
          expect { process }
            .to change { address_champ.reload.department_code }
            .from(nil).to("99")
        end
      end
    end
  end
end
