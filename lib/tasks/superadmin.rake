namespace :superadmin do
  desc <<~EOD
    List all super-admins
  EOD
  task list: :environment do
    puts "All Administrations:"
    Administration.all.pluck(:email).each do |a|
      puts a
    end
  end

  desc <<~EOD
    Create a new super-admin account with the #EMAIL email address.
  EOD
  task :create, [:email] => :environment do |_t, args|
    email = args[:email]

    puts "Creating Administration for #{email}"
    a = Administration.new(email: email, password: Devise.friendly_token[0, 20])

    if a.save
      puts "#{a.email} created"
    else
      puts "An error occured: #{a.errors.full_messages}"
    end
  end

  desc <<~EOD
    Delete the #EMAIL super-admin account
  EOD
  task :delete, [:email] => :environment do |_t, args|
    email = args[:email]
    puts "Deleting Administration for #{email}"
    a = Administration.find_by(email: email)
    a.destroy
    puts "#{a.email} deleted"
  end
end
