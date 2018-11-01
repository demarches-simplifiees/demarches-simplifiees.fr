module AccountConcern
  extend ActiveSupport::Concern

  included do
    helper_method :current_account,
      :current_usager,
      :current_instructeur,
      :current_manager,
      :account_signed_in?,
      :usager_signed_in?,
      :instructeur_signed_in?,
      :manager_signed_in?
  end

  def account_signed_in?
    current_account.signed_in?
  end

  def usager_signed_in?
    user_signed_in?
  end

  def instructeur_signed_in?
    gestionnaire_signed_in?
  end

  def manager_signed_in?
    administration_signed_in?
  end

  def current_account
    @current_account ||= Account.new(
      usager: current_user,
      instructeur: current_gestionnaire,
      administrateur: current_administrateur,
      manager: current_administration
    )
  end

  def current_usager
    current_user
  end

  def current_instructeur
    current_gestionnaire
  end

  def current_manager
    current_administration
  end

  def sign_out!
    sign_out(:user)
    sign_out(:gestionnaire)
    sign_out(:administrateur)
    sign_out(:administration)
    @current_account = Account.new
  end

  protected

  def authenticate_account!
    if instructeur_signed_in?
      authenticate_instructeur!
    end

    if administrateur_signed_in?
      authenticate_administrateur!
    end

    if manager_signed_in?
      authenticate_manager!
    end

    authenticate_usager!
  end

  def authenticate_usager!
    authenticate_user!
  end

  def authenticate_instructeur!
    if instructeur_signed_in?
      authenticate_gestionnaire!
    else
      redirect_to new_user_session_path
    end
  end

  def authenticate_administrateur!
    if administrateur_signed_in?
      super
    else
      redirect_to new_user_session_path
    end
  end

  def authenticate_manager!
    if manager_signed_in?
      authenticate_administration!
    else
      redirect_to new_user_session_path
    end
  end
end
