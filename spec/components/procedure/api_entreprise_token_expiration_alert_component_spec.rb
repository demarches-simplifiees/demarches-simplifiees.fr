# frozen_string_literal: true

require "rails_helper"

RSpec.describe Procedure::APIEntrepriseTokenExpirationAlertComponent, type: :component do
  subject { render_inline(described_class.new(procedure:)) }

  let(:procedure) { create(:procedure, api_entreprise_token:) }
  let(:url_helpers) { Rails.application.routes.url_helpers }

  context "when token is expired or expires soon" do
    let(:api_entreprise_token) { JWT.encode({ exp: 2.days.from_now.to_i }, nil, "none") }

    it "renders the alert" do
      expect(subject).to have_css('.fr-alert--error')
      expect(subject).to have_text('Des problèmes impactent le bon fonctionnement de la démarche')
      expect(subject).to have_text('Le')
      expect(subject).to have_text('est expiré ou va expirer prochainement')
    end

    it "renders the link to jetons path" do
      expect(subject).to have_link('Jeton API Entreprise', href: url_helpers.admin_procedure_jetons_path(procedure), class: 'error-anchor')
    end
  end

  context "when token expires in a long time" do
    let(:api_entreprise_token) { JWT.encode({ exp: 2.months.from_now.to_i }, nil, "none") }

    it "does not render" do
      expect(subject.to_html).to be_empty
    end
  end

  context "when there is no token" do
    let(:api_entreprise_token) { nil }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired_or_expires_soon?).and_return(false)
    end

    it "does not render" do
      expect(subject.to_html).to be_empty
    end
  end
end
