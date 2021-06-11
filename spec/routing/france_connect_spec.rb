require "rails_helper"

describe "FranceConnect routing", type: :routing do
  context "with FranceConnect disabled" do
    before(:all) do
      Rails.configuration.x.france_connect.enabled = false
      Rails.application.reload_routes!
    end

    it { expect(get: "/france_connect/particulier").not_to be_routable }
    it { expect(get: "/france_connect/particulier/callback").not_to be_routable }
    it { expect(get: "/commencer/:path/france_connect").not_to be_routable }
  end

  context "with FranceConnect enabled" do
    before(:all) do
      Rails.configuration.x.france_connect.enabled = true
      Rails.application.reload_routes!
    end

    it { expect(get: "/france_connect/particulier").to route_to(controller: "france_connect/particulier", action: "login") }
    it { expect(get: "/france_connect/particulier/callback").to route_to(controller: "france_connect/particulier", action: "callback") }
    it { expect(get: "/commencer/ma_demarche/france_connect").to route_to(controller: "users/commencer", action: "france_connect", path: "ma_demarche") }
  end
end
