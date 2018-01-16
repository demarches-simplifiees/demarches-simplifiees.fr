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

  def create
    administrateur = current_administration.invite_admin(create_administrateur_params[:email])

    if administrateur.errors.empty?
      flash.notice = "Administrateur créé"
    else
      flash.alert = administrateur.errors.full_messages
    end

    redirect_to administrations_path
  end

  def update
    Administrateur.find_inactive_by_id(params[:id]).invite!
  
    redirect_to administrations_path
  end

  private

  def create_administrateur_params
    params.require(:administrateur).permit(:email)
  end
end
