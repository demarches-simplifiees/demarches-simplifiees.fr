namespace :'2018_04_11_admin_or_gestionnaire_users' do
  task create_missing: :environment do
    create_missing_users(Administrateur)
    create_missing_users(Gestionnaire)
  end

  def create_missing_users(klass)
    klasses = klass.name.downcase.pluralize
    accounts = klass.joins("LEFT JOIN users on users.email = #{klasses}.email").where('users.id is null')
    processed_count = 0

    accounts.find_each(batch_size: 100) do |account|
      # To pass validation, we need to set dummy password even though
      # we override encrypted_password afterwards

      user = User.create({
        email: account.email,
        password: SecureRandom.hex(5),
        encrypted_password: account.encrypted_password
      })

      if user.persisted?
        processed_count += 1
      else
        print "Failed to create user for #{account.email}\n"
      end
    end

    print "Created users for #{processed_count} #{klasses}\n"
  end
end
