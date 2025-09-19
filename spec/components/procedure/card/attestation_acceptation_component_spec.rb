# frozen_string_literal: true

require "rails_helper"

RSpec.describe Procedure::Card::AttestationAcceptationComponent, type: :component do
  let(:component) { described_class.new(procedure:) }

  subject { render_inline(component) }

  let(:procedure) { create(:procedure) }
  let!(:attestation_acceptation_template) { create(:attestation_template, procedure:, kind: :acceptation, activated:, version:) }

  context "when version is 2" do
    let(:version) { 2 }
    context "when AttestationAcceptation is enabled" do
      let(:activated) { true }
      it do
        is_expected.to have_css('p.fr-badge.fr-badge--success', text: "Activée")
        is_expected.to have_css('h3.fr-h6', text: "Attestation d’acceptation")
        is_expected.to have_link(href: component.helpers.edit_admin_procedure_attestation_template_v2_path(procedure, attestation_kind: :acceptation))
      end
    end

    context "when AttestationAcceptation is disabled" do
      let(:activated) { false }
      it do
        is_expected.to have_css('p.fr-badge', text: "Désactivée")
        is_expected.to have_css('h3.fr-h6', text: "Attestation d’acceptation")
      end
    end
  end

  context "when version is 1" do
    let(:version) { 1 }
    context "when AttestationAcceptation is enabled" do
      let(:activated) { true }
      it { is_expected.to have_link(href: component.helpers.edit_admin_procedure_attestation_template_path(procedure)) }
    end
  end
end
