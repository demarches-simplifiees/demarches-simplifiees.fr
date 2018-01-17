class AdministrationsController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_administration!

  def index
    @admin = Administrateur.new

    @admins = smart_listing_create :admins,
      Administrateur.all.order(:email),
      partial: "administrations/list",
      array: true
  end

  def update
    Administrateur.find_inactive_by_id(params[:id]).invite!

    redirect_to administrations_path
  end
end
