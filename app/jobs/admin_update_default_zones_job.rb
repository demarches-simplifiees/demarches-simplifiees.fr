# frozen_string_literal: true

class AdminUpdateDefaultZonesJob < ApplicationJob
  def perform(admin)
    tchap_hs = APITchap::HsAdapter.new(admin.email).to_hs
    admin.default_zones << Zone.default_for(tchap_hs)
  end
end
