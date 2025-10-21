# frozen_string_literal: true

require 'rails_helper'

module Maintenance
  RSpec.describe T20251017destroyAttestationTemplatesV1WhenV2PublishedTask do
    describe "#collection" do
      subject { described_class.new.collection }

      context "with procedures having both v1 and v2 published attestation templates" do
        let!(:procedure_with_both) { create(:procedure) }
        let!(:v1_template) { create(:attestation_template, procedure: procedure_with_both, version: 1, state: 'published') }
        let!(:v2_template) { create(:attestation_template, procedure: procedure_with_both, version: 2, state: 'published', kind: 'acceptation') }

        it "includes the procedure" do
          expect(subject).to include(procedure_with_both.id)
        end
      end

      context "with procedures having v1 draft and v2 published" do
        let!(:procedure_v1_draft) { create(:procedure) }
        let!(:v1_draft) { create(:attestation_template, procedure: procedure_v1_draft, version: 1, state: 'draft') }
        let!(:v2_published) { create(:attestation_template, procedure: procedure_v1_draft, version: 2, state: 'published', kind: 'acceptation') }

        it "includes the procedure" do
          expect(subject).to include(procedure_v1_draft.id)
        end
      end

      context "with procedures having only v2 published" do
        let!(:procedure_v2_only) { create(:procedure) }
        let!(:v2_only) { create(:attestation_template, procedure: procedure_v2_only, version: 2, state: 'published', kind: 'acceptation') }

        it "does not include the procedure" do
          expect(subject).not_to include(procedure_v2_only.id)
        end
      end

      context "with procedures having only v1" do
        let!(:procedure_v1_only) { create(:procedure) }
        let!(:v1_only) { create(:attestation_template, procedure: procedure_v1_only, version: 1, state: 'published') }

        it "does not include the procedure" do
          expect(subject).not_to include(procedure_v1_only.id)
        end
      end

      context "with procedures having v2 draft and v1 published" do
        let!(:procedure_v2_draft) { create(:procedure) }
        let!(:v1_published) { create(:attestation_template, procedure: procedure_v2_draft, version: 1, state: 'published') }
        let!(:v2_draft) { create(:attestation_template, procedure: procedure_v2_draft, version: 2, state: 'draft', kind: 'acceptation') }

        it "does not include the procedure" do
          expect(subject).not_to include(procedure_v2_draft.id)
        end
      end

      context "with no attestation templates" do
        let!(:procedure_empty) { create(:procedure) }

        it "does not include the procedure" do
          expect(subject).not_to include(procedure_empty.id)
        end
      end
    end

    describe "#process" do
      let(:task) { described_class.new }
      let(:procedure) { create(:procedure) }

      context "when procedure has both v1 and v2 templates" do
        let!(:v1_template) { create(:attestation_template, procedure: procedure, version: 1, state: 'published') }
        let!(:v2_template) { create(:attestation_template, procedure: procedure, version: 2, state: 'published', kind: 'acceptation') }

        it "destroys only v1 templates" do
          expect { task.process(procedure.id) }
            .to change { AttestationTemplate.where(procedure: procedure, version: 1).count }.from(1).to(0)
            .and not_change { AttestationTemplate.where(procedure: procedure, version: 2).count }
        end

        it "keeps v2 templates intact" do
          task.process(procedure.id)
          expect(AttestationTemplate.find(v2_template.id)).to eq(v2_template)
        end
      end

      context "when procedure has multiple v1 templates" do
        let!(:v1_template_1) { create(:attestation_template, procedure: procedure, version: 1, state: 'published') }
        let!(:v1_template_2) { create(:attestation_template, procedure: procedure, version: 1, state: 'draft') }
        let!(:v2_template) { create(:attestation_template, procedure: procedure, version: 2, state: 'published', kind: 'acceptation') }

        it "destroys all v1 templates" do
          expect { task.process(procedure.id) }
            .to change { AttestationTemplate.where(procedure: procedure, version: 1).count }.from(2).to(0)
        end
      end

      context "when procedure has only v2 templates" do
        let!(:v2_template) { create(:attestation_template, procedure: procedure, version: 2, state: 'published', kind: 'acceptation') }

        it "does not raise error" do
          expect { task.process(procedure.id) }.not_to raise_error
        end

        it "does not destroy any templates" do
          expect { task.process(procedure.id) }
            .not_to change { AttestationTemplate.count }
        end
      end
    end
  end
end
