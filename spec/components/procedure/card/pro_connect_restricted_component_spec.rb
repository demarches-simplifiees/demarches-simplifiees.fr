# frozen_string_literal: true

require "rails_helper"

RSpec.describe Procedure::Card::ProConnectRestrictedComponent, type: :component do
  before do
    allow_any_instance_of(described_class).to receive(:feature_enabled?).and_return(true)
  end

  subject { render_inline(described_class.new(procedure:)) }

  let(:procedure) { create(:procedure, pro_connect_restricted:) }

  context "when no restriction" do
    let(:restriction_level) { :none }

    it do
      is_expected.to have_css('.fr-badge', text: "Aucune restriction")
      is_expected.to have_text("ProConnect")
    end
  end

  context "when restriction for instructeurs" do
    let(:restriction_level) { :instructeurs }

    it do
      is_expected.to have_css('.fr-badge.fr-badge--success', text: "Administrateurs et instructeurs")
    end
  end

  context "when restriction for all users" do
    let(:restriction_level) { :all }

    it do
      is_expected.to have_css('.fr-badge.fr-badge--success', text: "Tous les utilisateurs")
    end
  end
end
