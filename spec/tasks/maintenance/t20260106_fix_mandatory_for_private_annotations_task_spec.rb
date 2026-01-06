# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260106FixMandatoryForPrivateAnnotationsTask do
    let!(:private_tdc) { create_list(:type_de_champ, 3, private: true, mandatory: true) }
    let!(:public_tdc) { create_list(:type_de_champ, 2, private: false, mandatory: true) }

    describe "#collection" do
      it do
        expect(described_class.collection.first).to match_array(private_tdc)
      end
    end

    describe "#process" do
      let(:batch) { TypeDeChamp.where(id: private_tdc.map(&:id)).in_batches.first }

      it do
        described_class.process(batch)

        expect(batch.reload).to be_all { !it.mandatory? }
      end
    end
  end
end
