class AdministrationsController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_administration!

  def index

    @admins = smart_listing_create :admins,
                                   Administrateur.all,
                                   partial: "administrations/list",
                                   array: true

    @admin = Administrateur.new
  end

  def show
    @admin = Administrateur.find(params[:id])
  end

  def create
    admin = Administrateur.new create_administrateur_params

    if admin.save
      flash.notice = "Administrateur créé"
      NewAdminMailer.new_admin_email(admin, params[:administrateur][:password]).deliver_now!
    else
      flash.alert = admin.errors.full_messages.join('<br>').html_safe
    end

    redirect_to administrations_path
  end

  private

  def create_administrateur_params
    params.require(:administrateur).permit(:email, :password)
  end
end
