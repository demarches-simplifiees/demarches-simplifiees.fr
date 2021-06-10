# frozen_string_literal: true

require "rails_helper"

describe "API Particulier", type: :routing do
  let(:controller) { "new_administrateur/jetons_particulier" }

  context "when feature is enable" do
    before do
      Flipper.enable(:api_particulier)
    end

    it "must route to GET admin_procedure_jetons_particulier" do
      expect(get("/admin/procedures/1/jetons_particulier"))
        .to route_to(controller: controller, action: "index", procedure_id: "1")
    end

    it "must route to GET jeton_admin_procedure_jetons_particulier" do
      expect(get("/admin/procedures/1/jetons_particulier/jeton"))
        .to route_to(controller: controller, action: "jeton", procedure_id: "1")
    end

    it "must route to PATCH update_jeton_admin_procedure_jetons_particulier" do
      expect(patch("/admin/procedures/1/jetons_particulier/update_jeton"))
        .to route_to(controller: controller, action: "update_jeton", procedure_id: "1")
    end

    it "must route to GET sources_admin_procedure_jetons_particulier" do
      expect(get("/admin/procedures/1/jetons_particulier/sources"))
        .to route_to(controller: controller, action: "sources", procedure_id: "1")
    end

    it "must route to PATCH update_sources_admin_procedure_jetons_particulier" do
      expect(patch("/admin/procedures/1/jetons_particulier/update_sources"))
        .to route_to(controller: controller, action: "update_sources", procedure_id: "1")
    end

    it "must route to POST update_sources_admin_procedure_jetons_particulier" do
      expect(post("/admin/procedures/1/jetons_particulier/update_sources"))
        .to route_to(controller: controller, action: "update_sources", procedure_id: "1")
    end
  end

  context "when feature is disable" do
    before do
      Flipper.disable(:api_particulier)
    end

    it "must route to GET admin_procedure_jetons_particulier" do
      expect(get("/admin/procedures/1/jetons_particulier"))
        .to route_to(controller: controller, action: "index", procedure_id: "1")
    end

    it "wont route to GET jeton_admin_procedure_jetons_particulier" do
      expect(get("/admin/procedures/1/jetons_particulier/jeton")).not_to be_routable
    end

    it "wont route to PATCH update_jeton_admin_procedure_jetons_particulier" do
      expect(patch("/admin/procedures/1/jetons_particulier/update_jeton")).not_to be_routable
    end

    it "wont route to GET sources_admin_procedure_jetons_particulier" do
      expect(get("/admin/procedures/1/jetons_particulier/sources")).not_to be_routable
    end

    it "wont route to PATCH update_sources_admin_procedure_jetons_particulier" do
      expect(patch("/admin/procedures/1/jetons_particulier/update_sources")).not_to be_routable
    end

    it "wont route to POST update_sources_admin_procedure_jetons_particulier" do
      expect(post("/admin/procedures/1/jetons_particulier/update_sources")).not_to be_routable
    end
  end
end
