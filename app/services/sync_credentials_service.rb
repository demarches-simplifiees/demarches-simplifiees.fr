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
      if user && !user.update_columns(email: @email, encrypted_password: @encrypted_password)
        return false
      end
    end

    if @klass != Gestionnaire
      gestionnaire = Gestionnaire.find_by(email: @email_was)
      if gestionnaire && !gestionnaire.update_columns(email: @email, encrypted_password: @encrypted_password)
        return false
      end
    end

    if @klass != Administrateur
      administrateur = Administrateur.find_by(email: @email_was)
      if administrateur && !administrateur.update_columns(email: @email, encrypted_password: @encrypted_password)
        return false
      end
    end

    true
  end
end
