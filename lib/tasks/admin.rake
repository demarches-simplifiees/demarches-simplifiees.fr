namespace :admin do
  task :create_admin, [:email] => :environment do |t, args|
    email = args[:email]
    puts "Creating Administration for #{email}"
    a = Administration.new(email: email, password: Devise.friendly_token[0, 20])
    if a.save
      puts "#{a.email} created"
    else
      puts "An error occured : #{a.errors.full_messages}"
    end
  end

  task list: :environment do
    puts "All Administrations :"
    Administration.all.pluck(:email).each do |a|
      puts a
    end
  end

  task :delete_admin, [:email] => :environment do |t, args|
    email = args[:email]
    puts "Deleting Administration for #{email}"
    a = Administration.find_by(email: email)
    a.destroy
    puts "#{a.email} deleted"
  end
end
