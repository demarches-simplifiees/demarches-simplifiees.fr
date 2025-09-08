# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250908backfillAttestationTemplatesKindTask do
    describe "#process" do
      subject(:process) { described_class.new.process(batch) }

      let(:batch) { AttestationTemplate.where(kind: nil) }

      before { create_list(:attestation_template, 3, kind: nil) }

      it "backfills all attestations in batch with kind :acceptation" do
        expect { process }
          .to change { AttestationTemplate.where(kind: 'acceptation').count }
          .from(0)
          .to(3)
      end
    end

    describe "#collection" do
      subject(:collection) { described_class.new.collection }

      let!(:without_kind) { create_list(:attestation_template, 2, kind: nil) }
      let!(:with_kind) { create(:attestation_template, kind: :acceptation) }

      it "contains only attestation without kind" do
        collected_ids = collection.flat_map(&:ids)

        expect(collected_ids).to match_array(without_kind.map(&:id))
        expect(collected_ids).not_to include(with_kind.id)
      end
    end
  end
end
