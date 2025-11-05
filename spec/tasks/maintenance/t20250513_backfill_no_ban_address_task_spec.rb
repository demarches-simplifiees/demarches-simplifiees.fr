# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250513BackfillNoBanAddressTask do
    describe "#process" do
      subject(:process) { described_class.process(champ) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :address }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:address_champ) { dossier.champs.first }

      it do
        address_champ.update_columns(value: "123 Main St", value_json: {})
        expect(address_champ.full_address?).to be_falsey
        expect(address_champ.ban?).to be_falsey
        expect(address_champ.street_address).to eq("123 Main St")
        expect(address_champ.address_label).to eq("123 Main St")
        expect(address_champ.value_json).to be_blank
        expect(address_champ.legacy_not_ban?).to be_truthy
        described_class.process(address_champ)
        expect(address_champ.full_address?).to be_falsey
        expect(address_champ.ban?).to be_falsey
        expect(address_champ.street_address).to eq("123 Main St")
        expect(address_champ.address_label).to eq("123 Main St")
        expect(address_champ.value_json).to eq({
          street_address: '123 Main St',
          label: '123 Main St',
          not_in_ban: 'true',
        }.stringify_keys)
      end
    end
  end
end
