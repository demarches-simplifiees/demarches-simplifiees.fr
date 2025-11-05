# frozen_string_literal: true

class Gestionnaires::ActivateController < ApplicationController
  include TrustedDeviceConcern

  def new
    @token = params[:token]

    user = User.with_reset_password_token(@token)
    @gestionnaire = user&.gestionnaire

    if @gestionnaire
      # the gestionnaire activates its account from an email
      trust_device(Time.zone.now)
    else
      flash.alert = "Le lien de validation de gestionnaire a expiré, #{helpers.contact_link('contactez-nous', tags: 'lien expiré')} pour obtenir un nouveau lien."
      redirect_to root_path
    end
  end

  def create
    password = update_gestionnaire_params[:password]

    user = User.reset_password_by_token({
      password: password,
      password_confirmation: password,
      reset_password_token: update_gestionnaire_params[:reset_password_token],
    })

    if user&.errors&.empty?
      sign_in(user, scope: :user)

      flash.notice = "Mot de passe enregistré"
      redirect_to gestionnaire_groupe_gestionnaires_path
    else
      flash.alert = user.errors.full_messages
      redirect_to gestionnaires_activate_path(token: update_gestionnaire_params[:reset_password_token])
    end
  end

  private

  def update_gestionnaire_params
    params.require(:gestionnaire).permit(:reset_password_token, :password)
  end

  def try_to_authenticate(klass, email, password)
    resource = klass.find_for_database_authentication(email: email)

    if resource&.valid_password?(password)
      sign_in resource
    end
  end
end
