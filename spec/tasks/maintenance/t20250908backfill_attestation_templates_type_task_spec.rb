# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250908backfillAttestationTemplatesTypeTask do
    describe "#process" do
      subject(:process) { described_class.new.process(batch) }

      let(:batch) { AttestationTemplate.all }

      before { create_list(:attestation_template, 3, type: nil) }

      it "backfill attestation with type :acceptation" do
        expect { process }
          .to change { batch.first.reload.type }
          .from(nil)
          .to("acceptation")
      end
    end

    describe "#collection" do
      subject(:collection) { described_class.new.collection }

      let!(:with_nil_type) { create(:attestation_template, type: nil) }
      let!(:with_type)     { create(:attestation_template, type: :acceptation) }

      it "contains only attestation without type" do
        collected_ids = collection.flat_map(&:ids)

        expect(collected_ids.size).to eq(1)
        expect(collected_ids).not_to include(with_type.id)
        expect(collected_ids).to include(with_nil_type.id)
      end
    end
  end
end
