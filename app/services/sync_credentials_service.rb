class SyncCredentialsService
  def initialize klass, email_was, email, encrypted_password
    @klass = klass
    @email_was = email_was
    @email = email
    @encrypted_password = encrypted_password
  end

  def change_credentials!
    if @klass != User
      user = User.find_by(email: @email_was)
      if user
        return false if !user.update_columns(
            email: @email,
            encrypted_password: @encrypted_password)
      end
    end

    if @klass != Gestionnaire
      gestionnaire = Gestionnaire.find_by(email: @email_was)
      if gestionnaire
        return false if !gestionnaire.update_columns(
            email: @email,
            encrypted_password: @encrypted_password)
      end
    end

    if @klass != Administrateur
      administrateur = Administrateur.find_by(email: @email_was)
      if administrateur
        return false if !administrateur.update_columns(
            email: @email,
            encrypted_password: @encrypted_password)
      end
    end

    true
  end
end
