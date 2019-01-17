class InvitesController < ApplicationController
  include Devise::StoreLocationExtension

  before_action :authenticate_user!, only: [:create]
  before_action :store_user_location!, only: [:show]

  def create
    email = params[:invite_email].downcase
    dossier = current_user.dossiers.find(params[:dossier_id])

    invite = Invite.create(
      dossier: dossier,
      user: User.find_by(email: email),
      email: email,
      email_sender: current_user.email
    )

    if invite.valid?
      if invite.user.present?
        InviteMailer.invite_user(invite).deliver_later
      else
        InviteMailer.invite_guest(invite).deliver_later
      end

      flash.notice = "Une invitation a été envoyée à #{invite.email}."
    else
      flash.alert = invite.errors.full_messages
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: helpers.url_for_dossier(dossier)) }
      format.js { @dossier = dossier }
    end
  end

  def show
    if user_signed_in?
      erase_user_location!

      dossier = Dossier.joins(:invites)
        .find_by!(invites: { email: current_user.email, id: params[:id] })

      if dossier.brouillon?
        redirect_to brouillon_dossier_path(dossier)
      else
        redirect_to dossier_path(dossier)
      end
    elsif params[:email].present? && !User.find_by(email: params[:email])
      redirect_to new_user_registration_path(user: { email: params[:email] })
    else
      authenticate_user!
    end
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to dossiers_path
  end

  private

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def erase_user_location!
    clear_stored_location_for(:user)
  end
end
