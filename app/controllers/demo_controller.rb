class DemoController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  def index
    return redirect_to root_path if Rails.env.production?

    smart_listing_create :procedures,
      Procedure.published.where(archived: false).order("id DESC"),
      partial: "demo/list",
      array: true
  end
end
