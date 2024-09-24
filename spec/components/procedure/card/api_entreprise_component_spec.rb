# frozen_string_literal: true

require "rails_helper"

RSpec.describe Procedure::Card::APIEntrepriseComponent, type: :component do
  subject { render_inline(described_class.new(procedure:)) }

  let(:procedure) { create(:procedure, api_entreprise_token:) }

  context "Token is not configured" do
    let(:api_entreprise_token) { nil }

    it { is_expected.to have_css('p.fr-badge.fr-badge--info', text: "À configurer") }
  end

  context "Token expires soon" do
    let(:api_entreprise_token) { JWT.encode({ exp: 2.days.from_now.to_i }, nil, "none") }

    it { is_expected.to have_css('p.fr-badge.fr-badge--error', text: "À renouveler") }
  end

  context "Token expires in a long time" do
    let(:api_entreprise_token) { JWT.encode({ exp: 2.months.from_now.to_i }, nil, "none") }

    it { is_expected.to have_css('p.fr-badge.fr-badge--success', text: "Validé") }
  end
end
