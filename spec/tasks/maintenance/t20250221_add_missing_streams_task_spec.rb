# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250221AddMissingStreamsTask do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{}] }]) }
    let!(:dossiers) { create_list(:dossier, 3, :with_populated_champs, procedure:) }

    before { Champs::RepetitionChamp.update_all(stream: nil) }

    describe "#collection" do
      subject(:collection) { described_class.collection }

      it "returns the number of batches" do
        expect(collection).to eq([0])
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(0) }

      it "returns the number of batches" do
        expect { process }.to change { Champs::RepetitionChamp.where(stream: nil).count }.from(6).to(0)
      end
    end
  end
end
