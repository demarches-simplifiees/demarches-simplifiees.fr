# frozen_string_literal: true

require "rails_helper"

RSpec.describe SwitchDomainBannerComponent, type: :component do
  let(:app_host_legacy) { "legacy.host" }
  let(:app_host) { "new.host.fr" }

  let(:user) { create(:user) }
  let(:request_host) { app_host_legacy }
  let(:path) { "/" }

  before do
    stub_const("ApplicationHelper::APP_HOST_LEGACY", app_host_legacy)
    stub_const("ApplicationHelper::APP_HOST", app_host)

    Flipper.enable(:switch_domain)
  end

  after do
    Flipper.disable(:switch_domain)
  end

  subject(:rendered) do
    with_request_url path, host: request_host, format: nil do
      render_inline(described_class.new(user: user))
    end
  end

  context "when request is already on APP_HOST" do
    let(:request_host) { app_host }

    it "does not render the component" do
      expect(rendered.to_html).to include(APPLICATION_NAME)
      expect(rendered.to_html).not_to include("window.location")
      expect(rendered.to_html).not_to include("Suivez ce lien")
    end
  end

  describe "URL generation" do
    context "with a logged-in user" do
      let(:path) { "/admin/procedures" }
      before do
        allow(user).to receive(:authenticable_token).and_return("token123")
      end

      it "includes the authenticable_token in the URL" do
        expect(rendered.to_html).to have_link(APPLICATION_NAME, href: "http://new.host.fr/admin/procedures?authenticable_token=token123")
        expect(rendered.to_html).not_to include("window.location")
        expect(rendered.to_html).to include("Suivez ce lien")
      end
    end

    context "without a logged-in user" do
      let(:user) { nil }
      let(:path) { "/commencer/boom" }

      it "render auto switch JS and does not include the authenticable_token in the URL" do
        expect(rendered.to_html).to have_link(APPLICATION_NAME, href: "http://new.host.fr/commencer/boom")
        expect(rendered.to_html).to include("window.location = 'http://new.host.fr/commencer/boom'")
        expect(rendered.to_html).to include("erreur")
      end
    end
  end
end
