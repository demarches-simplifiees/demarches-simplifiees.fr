# frozen_string_literal: true

require "rails_helper"

RSpec.describe Procedure::Card::AttestationRefusComponent, type: :component do
  let(:component) { described_class.new(procedure:) }

  subject { render_inline(component) }

  let(:procedure) { create(:procedure) }
  let!(:attestation_refus_template) { create(:attestation_template, procedure:, kind: :refus, activated:, version: 2) }

  context "when AttestationRefus is enabled" do
    let(:activated) { true }
    it do
      is_expected.to have_css('p.fr-badge.fr-badge--success', text: "Activée")
      is_expected.to have_css('h3.fr-h6', text: "Attestation de refus")
      is_expected.to have_link(href: component.helpers.edit_admin_procedure_attestation_template_v2_path(procedure, attestation_kind: :refus))
    end
  end

  context "when AttestationRefus is disabled" do
    let(:activated) { false }
    it do
      is_expected.to have_css('p.fr-badge', text: "Désactivée")
      is_expected.to have_css('h3.fr-h6', text: "Attestation de refus")
    end
  end
end
