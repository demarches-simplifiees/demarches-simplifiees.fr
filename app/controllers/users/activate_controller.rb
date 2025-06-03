# frozen_string_literal: true

class Users::ActivateController < ApplicationController
  include TrustedDeviceConcern

  def new
    @user = User.with_reset_password_token(params[:token])

    if @user
      # the user activates its account from an email
      trust_device(Time.zone.now)
    else
      flash.alert = "Le lien de validation a expiré, #{helpers.contact_link('contactez-nous', tags: 'lien expiré')} pour obtenir un nouveau lien."
      redirect_to root_path
    end
  end

  def create
    user = User.reset_password_by_token({
      password: user_params[:password],
      reset_password_token: user_params[:reset_password_token]
    })

    if user.valid?
      sign_in(user, scope: :user)

      flash.notice = "Mot de passe enregistré"
      path = if user.administrateur?
        admin_procedures_path
      elsif user.instructeur?
        instructeur_procedures_path
      else
        users_dossiers_path
      end
      redirect_to path
    else
      flash.alert = user.errors.full_messages
      redirect_to users_activate_path(token: user_params[:reset_password_token])
    end
  end

  def confirm_email
    user = User.find_by(confirmation_token: params[:token])
    if user && user.email_verified_at
      flash[:notice] = "Votre email est déjà vérifié"
    elsif user && user.confirmation_sent_at >= 2.days.ago
      user.update!(email_verified_at: Time.zone.now)
      flash[:notice] = 'Votre email a bien été vérifié'
    else
      if user.present?
        flash[:alert] = "Ce lien n'est plus valable, un nouveau lien a été envoyé à l'adresse #{user.email}"
        user.resend_confirmation_email!
      else
        flash[:alert] = "Un problème est survenu, vous pouvez nous contacter sur #{Current.contact_email}"
      end
    end
    redirect_to root_path(user)
  end

  private

  def user_params
    params.require(:user).permit(:reset_password_token, :password)
  end
end
