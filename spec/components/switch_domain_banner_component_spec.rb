# frozen_string_literal: true

require "rails_helper"

RSpec.describe SwitchDomainBannerComponent, type: :component do
  let(:app_host_legacy) { "demarches-simplifiees.fr" }
  let(:app_host) { "demarches.numerique.gouv.fr" }

  let(:user) { create(:user) }
  let(:request_host) { app_host_legacy }
  let(:path) { "/" }

  before do
    allow(Current).to receive(:host).and_return(app_host)
    stub_const("ApplicationHelper::APP_HOST_LEGACY", app_host_legacy)
    stub_const("ApplicationHelper::APP_HOST", app_host)

    Flipper.enable(:switch_domain)
  end

  after do
    Flipper.disable(:switch_domain)
  end

  subject(:rendered) do
    with_request_url path, host: request_host do
      render_inline(described_class.new(user: user))
    end
  end

  context "when request is already on APP_HOST" do
    let(:request_host) { app_host }

    it "notify about names change" do
      expect(rendered.to_html).to include("demarches-simplifiees.fr")
      expect(rendered.to_html).to include(app_host)
      expect(rendered.to_html).not_to include("window.location")
      expect(rendered.to_html).not_to include("Suivez ce lien")
    end

    context "when user has already set preferred domain" do
      let(:user) { create(:user, preferred_domain: :demarches_numerique_gouv_fr) }

      it "does not render the banner" do
        expect(rendered.to_html).to be_empty
      end
    end
  end

  describe "URL generation" do
    let(:path) { "/admin/procedures" }

    it "generate an url to the new domain" do
      expect(rendered.to_html).to have_link("demarches.numerique.gouv.fr", href: "http://demarches.numerique.gouv.fr/admin/procedures")
      expect(rendered.to_html).not_to include("window.location")
      expect(rendered.to_html).to include("Suivez ce lien")
    end
  end
end
