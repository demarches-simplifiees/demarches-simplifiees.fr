class InvitesController < ApplicationController
  before_action :gestionnaire_or_user?

  def create
    email_sender = @current_devise_profil.email

    class_var = @current_devise_profil.class == User ? InviteUser : InviteGestionnaire
    dossier = @current_devise_profil.dossiers.find(params[:dossier_id])

    email = params[:email].downcase

    user = User.find_by(email: email)
    invite = class_var.create(dossier: dossier, user: user, email: email, email_sender: email_sender)

    if invite.valid?
      if invite.user.present?
        InviteMailer.invite_user(invite).deliver_now!
      else
        InviteMailer.invite_guest(invite).deliver_now!
      end

      flash.notice = "Invitation envoyée (#{invite.email})"
    else
      flash.alert = invite.errors.full_messages
    end

    redirect_to url_for(controller: 'users/recapitulatif', action: :show, dossier_id: params['dossier_id'])
  end

  private

  def gestionnaire_or_user?
    if !user_signed_in?
      return redirect_to root_path
    end

    @current_devise_profil = current_user if user_signed_in?
  end
end
