# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe NormalizeRNAValuesTask do
    describe "#process" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :rna }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:element) { dossier.champs.first }
      subject(:process) { described_class.process(element) }
      let(:error_value) { "999 0 999" }
      it "removes extra spaces" do
        element.update_column(:value, error_value)
        expect { subject }.to change { element.reload.value }.from(error_value).to("9990999")
      end
    end
  end
end
