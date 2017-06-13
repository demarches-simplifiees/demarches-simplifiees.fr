class SyncCredentialsService
  def initialize klass, email_was, email, encrypted_password
    @klass = klass
    @email_was = email_was
    @email = email
    @encrypted_password = encrypted_password
  end

  def change_credentials!
    unless @klass == User
      user = User.find_by(email: @email_was)
      if user
        return false unless user.update_columns(
            email: @email,
            encrypted_password: @encrypted_password)
      end
    end

    unless @klass == Gestionnaire
      gestionnaire = Gestionnaire.find_by(email: @email_was)
      if gestionnaire
        return false unless gestionnaire.update_columns(
            email: @email,
            encrypted_password: @encrypted_password)
      end
    end

    unless @klass == Administrateur
      administrateur = Administrateur.find_by(email: @email_was)
      if administrateur
        return false unless administrateur.update_columns(
            email: @email,
            encrypted_password: @encrypted_password)
      end
    end

    true
  end
end
