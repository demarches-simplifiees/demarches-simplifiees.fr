require Rails.root.join("lib", "tasks", "task_helper")

namespace :superadmin do
  desc <<~EOD
    List all super-admins
  EOD
  task list: :environment do
    rake_puts "All Administrations:"
    Administration.all.pluck(:email).each do |a|
      puts a
    end
  end

  desc <<~EOD
    Create a new super-admin account with the #EMAIL email address.
  EOD
  task :create, [:email] => :environment do |_t, args|
    email = args[:email]

    rake_puts "Creating Administration for #{email}"
    a = Administration.new(email: email, password: Devise.friendly_token[0, 20])

    if a.save
      rake_puts "#{a.email} created"
    else
      rake_puts "An error occured: #{a.errors.full_messages}"
    end
  end

  desc <<~EOD
    Delete the #EMAIL super-admin account
  EOD
  task :delete, [:email] => :environment do |_t, args|
    email = args[:email]
    rake_puts "Deleting Administration for #{email}"
    a = Administration.find_by(email: email)
    a.destroy
    rake_puts "#{a.email} deleted"
  end
end
