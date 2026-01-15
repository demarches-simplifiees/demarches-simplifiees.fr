# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260114backfillDossierSubmittedMessageJSONBodyTask do
    describe "#collection" do
      let!(:dsm_with_text) { create(:dossier_submitted_message, message_on_submit_by_usager: "Hello", json_body: nil) }
      let!(:dsm_already_converted) { create(:dossier_submitted_message, message_on_submit_by_usager: "World", json_body: { "type" => "doc" }) }
      let!(:dsm_empty) { create(:dossier_submitted_message, message_on_submit_by_usager: nil, json_body: nil) }

      it 'returns only messages needing conversion' do
        expect(described_class.new.collection).to contain_exactly(dsm_with_text)
      end
    end

    describe "#process" do
      let(:dsm) { create(:dossier_submitted_message, message_on_submit_by_usager: "Hello world", json_body: nil) }

      it 'converts text to tiptap JSON' do
        described_class.new.process(dsm)
        dsm.reload
        expect(dsm.json_body).to be_present
        expect(dsm.json_body["type"]).to eq("doc")
        expect(dsm.json_body["content"].first["content"].first["text"]).to eq("Hello world")
      end

      context 'with multiple paragraphs' do
        let(:dsm) { create(:dossier_submitted_message, message_on_submit_by_usager: "First\n\nSecond", json_body: nil) }

        it 'creates separate paragraphs' do
          described_class.new.process(dsm)
          dsm.reload
          expect(dsm.json_body["content"].length).to eq(2)
        end
      end
    end
  end
end
