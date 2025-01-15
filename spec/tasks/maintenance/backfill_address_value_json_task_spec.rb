# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe BackfillAddressValueJSONTask do
    describe "#process" do
      subject(:process) { described_class.process }

      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :address, libelle: 'address' }]) }
      let(:dossier) { create(:dossier, procedure:) }
      let(:address_champ) { dossier.project_champs_public.first }
      let(:address_data) { { 'address' => 'address' } }

      before { address_champ.update(data: address_data) }

      it do
        expect(address_champ.value_json).to be_nil

        process
        address_champ.reload

        expect(address_champ.value_json).to eq(address_data)
      end
    end
  end
end
