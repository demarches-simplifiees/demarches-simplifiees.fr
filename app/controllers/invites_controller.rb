class InvitesController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :store_user_location!, only: [:show]

  def create
    email = params[:invite_email].downcase
    @dossier = current_user.dossiers.visible_by_user.find(params[:dossier_id])
    invite = Invite.create(
      dossier: @dossier,
      user: User.find_by(email: email),
      email: email,
      message: params[:invite_message],
      email_sender: current_user.email
    )

    if invite.valid?
      # The notification is sent through an after commit hook in order to avoir concurrency issues
      flash.notice = "Une invitation a été envoyée à #{invite.email}."
    else
      flash.alert = invite.errors.full_messages
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: helpers.url_for_dossier(@dossier)) }
      format.turbo_stream
    end
  end

  def show
    if user_signed_in?
      erase_user_location!
      dossier = Dossier.joins(:invites)
        .find_by!(invites: { email: current_user.email, id: params[:id] })

      redirect_to helpers.url_for_dossier(dossier)
    elsif params[:email].present? && !User.find_by(email: params[:email])
      redirect_to new_user_registration_path(user: { email: params[:email] })
    else
      authenticate_user!
    end
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to dossiers_path
  end

  def destroy
    invite = Invite.find(params[:id])
    @dossier = invite.dossier

    if @dossier.user == current_user
      invite.destroy!
      flash.notice = "L’autorisation de #{invite.email} vient d’être révoquée."
    else
      flash.alert = "Vous ne pouvez pas révoquer cette autorisation"
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: helpers.url_for_dossier(@dossier)) }
      format.turbo_stream
    end
  end

  private

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def erase_user_location!
    clear_stored_location_for(:user)
  end
end
