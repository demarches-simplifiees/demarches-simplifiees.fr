# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250908backfillAttestationTemplatesTypeTask do
    describe "#process" do
      subject(:process) { described_class.new.process(element) }

      let(:element) { create(:attestation_template, type: nil) }

      it "backfill attestation with type :acceptation" do
        expect { process }
          .to change { element.reload.type }
          .from(nil)
          .to("acceptation")
      end
    end

    describe "#collection" do
      subject(:collection) { described_class.new.collection }

      let!(:with_nil_type) { create(:attestation_template, type: nil) }
      let!(:with_type)     { create(:attestation_template, type: :acceptation) }

      it "contains only attestation without type" do
        expect(collection).to contain_exactly(with_nil_type)
      end
    end
  end
end
