require "rails_helper"

describe "FranceConnect routing", type: :routing do
  context "with FranceConnect disabled" do
    before(:all) do
      @fc_enabled = Flipper.enabled?(:france_connect)
      Flipper.disable(:france_connect) if @fc_enabled
      Rails.application.reload_routes!
    end

    after(:all) do
      Flipper.enable(:france_connect) if @fc_enabled
    end

    it { expect(get: "/france_connect/particulier").not_to be_routable }
    it { expect(get: "/france_connect/particulier/callback").not_to be_routable }
    it { expect(get: "/commencer/:path/france_connect").not_to be_routable }
  end

  context "with FranceConnect enabled" do
    before(:all) do
      @fc_enabled = Flipper.enabled?(:france_connect)
      Flipper.enable(:france_connect) if !@fc_enabled
      Rails.application.reload_routes!
    end

    after(:all) do
      Flipper.disable(:france_connect) if !@fc_enabled
    end

    it { expect(get: "/france_connect/particulier").to route_to(controller: "france_connect/particulier", action: "login") }
    it { expect(get: "/france_connect/particulier/callback").to route_to(controller: "france_connect/particulier", action: "callback") }
    it { expect(get: "/commencer/ma_demarche/france_connect").to route_to(controller: "users/commencer", action: "france_connect", path: "ma_demarche") }
  end
end
