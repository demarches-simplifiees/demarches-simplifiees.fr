# frozen_string_literal: true

require Rails.root.join("lib", "tasks", "task_helper")

namespace :superadmin do
  desc <<~EOD
    List all super-admins
  EOD
  task list: :environment do
    rake_puts "All SuperAdmins:"
    SuperAdmin.pluck(:email).each do |a|
      puts a
    end
  end

  desc <<~EOD
    Create a new super-admin account with the #EMAIL email address.
  EOD
  task :create, [:email] => :environment do |_t, args|
    email = args[:email]

    rake_puts "Creating SuperAdmin for #{email}"
    password = Devise.friendly_token
    a = SuperAdmin.new(email:, password:)

    if a.save
      rake_puts "#{a.email} created"
      a.send_reset_password_instructions
      rake_puts "Password reset instructions sent to #{a.email}"

      user = User.create_or_promote_to_administrateur(email, password)

      user.update!(team_account: true)
    else
      rake_puts "An error occured: #{a.errors.full_messages}"
    end
  end

  desc <<~EOD
    Delete the #EMAIL super-admin account
  EOD
  task :delete, [:email] => :environment do |_t, args|
    email = args[:email]
    rake_puts "Deleting SuperAdmin for #{email}"
    a = SuperAdmin.find_by(email: email)
    a.destroy
    rake_puts "#{a.email} deleted"
  end
end
