class Administrateurs::ActivateController < ApplicationController
  include TrustedDeviceConcern

  def new
    @token = params[:token]

    user = User.with_reset_password_token(@token)
    @administrateur = user&.administrateur

    if @administrateur
      # the administrateur activates its account from an email
      trust_device(Time.zone.now)
    else
      flash.alert = "Le lien de validation d'administrateur a expiré, #{helpers.contact_link('contactez-nous', tags: 'lien expiré')} pour obtenir un nouveau lien."
      redirect_to root_path
    end
  end

  def create
    password = update_administrateur_params[:password]

    user = User.reset_password_by_token({
      password: password,
      password_confirmation: password,
      reset_password_token: update_administrateur_params[:reset_password_token]
    })

    if user&.administrateur&.errors&.empty?
      sign_in(user, scope: :user)

      flash.notice = "Mot de passe enregistré"
      redirect_to admin_procedures_path
    else
      flash.alert = administrateur.errors.full_messages
      redirect_to admin_activate_path(token: update_administrateur_params[:reset_password_token])
    end
  end

  def test_strength
    @score, @words, @length = ZxcvbnService.new(update_administrateur_params[:password]).complexity
    @min_length = PASSWORD_MIN_LENGTH
    @min_complexity = PASSWORD_COMPLEXITY_FOR_ADMIN
    render 'shared/password/test_strength'
  end

  private

  def update_administrateur_params
    params.require(:administrateur).permit(:password, :reset_password_token)
  end

  def try_to_authenticate(klass, email, password)
    resource = klass.find_for_database_authentication(email: email)

    if resource&.valid_password?(password)
      sign_in resource
      resource.force_sync_credentials
    end
  end
end
