class Users::ActivateController < ApplicationController
  include TrustedDeviceConcern

  def new
    @user = User.with_reset_password_token(params[:token])

    if @user
      # the user activates its account from an email
      if @user&.administrateur
        complexity = PASSWORD_COMPLEXITY_FOR_ADMIN
      elsif @user&.instructeur
        complexity = PASSWORD_COMPLEXITY_FOR_INSTRUCTEUR
      else
        complexity = PASSWORD_COMPLEXITY_FOR_USER
      end
      @test_password_strength = test_password_strength_path(complexity)
      trust_device(Time.zone.now)
    else
      flash.alert = "Le lien de validation du compte instructeur a expiré, #{helpers.contact_link('contactez-nous', tags: 'lien expiré')} pour obtenir un nouveau lien."
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
      redirect_to instructeur_procedures_path
    else
      flash.alert = user.errors.full_messages
      redirect_to users_activate_path(token: user_params[:reset_password_token])
    end
  end

  private

  def user_params
    params.require(:user).permit(:reset_password_token, :password)
  end
end
