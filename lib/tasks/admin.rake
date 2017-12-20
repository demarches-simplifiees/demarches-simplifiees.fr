namespace :admin do
  task :create_admin, [:email] => :environment do |t, args|
    email = args[:email]
    puts "Creating Administration for #{email}"
    a = Administration.new(email: email, password: Devise.friendly_token[0,20])
    if a.save
      puts "#{a.email} created"
    else
      puts "An error occured : #{a.errors.full_messages}"
    end
  end
end
