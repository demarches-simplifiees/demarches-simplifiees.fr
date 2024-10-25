# frozen_string_literal: true

require "rails_helper"

RSpec.describe Procedure::Card::RdvComponent, type: :component do
  subject { render_inline(described_class.new(procedure:)) }

  let(:procedure) { create(:procedure, rdv_enabled:) }

  context "when RDV is enabled" do
    let(:rdv_enabled) { true }

    it { is_expected.to have_css('p.fr-badge.fr-badge--success', text: "Activée") }
    it { is_expected.to have_css('h3.fr-h6', text: "Prise de rendez-vous") }
  end

  context "when RDV is disabled" do
    let(:rdv_enabled) { false }

    it { is_expected.to have_css('p.fr-badge', text: "Désactivée") }
    it { is_expected.to have_css('h3.fr-h6', text: "Prise de rendez-vous") }
  end
end
