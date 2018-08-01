class InvitesController < ApplicationController
  before_action :ensure_user_signed_in

  def create
    email = params[:invite_email].downcase

    invite = InviteUser.create(
      dossier: current_user.dossiers.find(params[:dossier_id]),
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

      flash.notice = "Invitation envoyée (#{invite.email})"
    else
      flash.alert = invite.errors.full_messages
    end

    redirect_to url_for(controller: 'users/recapitulatif', action: :show, dossier_id: params['dossier_id'])
  end

  private

  def ensure_user_signed_in
    if !user_signed_in?
      return redirect_to root_path
    end
  end
end
