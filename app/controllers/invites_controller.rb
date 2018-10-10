class InvitesController < ApplicationController
  before_action :ensure_user_signed_in

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

  private

  def ensure_user_signed_in
    if !user_signed_in?
      return redirect_to root_path
    end
  end
end
