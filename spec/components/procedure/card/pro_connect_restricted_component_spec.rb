# frozen_string_literal: true

require "rails_helper"

RSpec.describe Procedure::Card::ProConnectRestrictedComponent, type: :component do
  before do
    allow_any_instance_of(described_class).to receive(:feature_enabled?).and_return(true)
  end

  subject { render_inline(described_class.new(procedure:)) }

  let(:procedure) { create(:procedure, pro_connect_restricted:) }

  context "when ProConnect restriction is enabled" do
    let(:pro_connect_restricted) { true }

    it do
      is_expected.to have_css('p.fr-badge.fr-badge--success', text: "Activée")
      is_expected.to have_css('h3.fr-h6', text: "ProConnect")
    end
  end

  context "when ProConnect restriction is disabled" do
    let(:pro_connect_restricted) { false }

    it do
      is_expected.to have_css('p.fr-badge', text: "Désactivée")
      is_expected.to have_css('h3.fr-h6', text: "ProConnect")
    end
  end
end
