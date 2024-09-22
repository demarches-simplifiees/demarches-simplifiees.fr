# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe DossierAttributesTask do
    let(:procedure) { create(:procedure, :with_all_annotations) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure: procedure) }
    # let (:logger) { instance_double("Rails::Logger") }

    describe "#process" do
      subject { described_class.process(element) }
      let(:element) { dossier.champs.first }
      it "execute witout error" do
        subject
      end
    end

    describe "#collection" do
      let(:task) { described_class.new.tap { |task| task.dossier = dossier.id } }

      it "gets back all champ from dossier" do
        expect(task.collection.count).to eq(dossier.champs.count)
      end
    end
  end
end
