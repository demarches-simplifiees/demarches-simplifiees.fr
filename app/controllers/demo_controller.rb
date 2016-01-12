class DemoController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  def index
    smart_listing_create :procedures,
                         Procedure.where(archived: false),
                         partial: "demo/list",
                         array: true
  end
end
