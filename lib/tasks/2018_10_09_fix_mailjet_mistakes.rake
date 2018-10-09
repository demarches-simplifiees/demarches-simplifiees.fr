namespace :'2018_10_03_fix_mailjet_mistakes' do
  task activation_emails: :environment do
    activation_file_path = ENV['ACTIVATION']

    if File.file?(activation_file_path)
      rake_puts "loading #{activation_file_path} file for account activation"
    else
      rake_puts "no file #{activation_file_path} found"
    end

    emails = File.new(activation_file_path).readlines.map(&:strip)

    emails.each do |email|
      user = User.find_by(email: email)
      if user.present?
        rake_puts "sending activation mail for #{email}"
        if user.confirmed?
          UserMailer.new_account_warning(user).deliver_later
        else
          user.resend_confirmation_instructions
        end
      else
        rake_puts "user #{email} does not exist"
      end
    end
  end

  task password_emails: :environment do
    password_file_path = ENV['PASSWORD']

    if File.file?(password_file_path)
      rake_puts "loading #{password_file_path} file for changing password"
    else
      rake_puts "no file #{password_file_path} found"
    end

    emails = File.new(password_file_path).readlines.map(&:strip)

    emails.each do |email|
      user = User.find_by(email: email)
      if user.present?
        rake_puts "sending changing password mail for #{email}"
        user.send_reset_password_instructions
      else
        rake_puts "user #{email} does not exist"
      end
    end
  end

  task notification_emails: :environment do
    notification_file_path = ENV['NOTIFICATION']

    if File.file?(notification_file_path)
      rake_puts "loading #{notification_file_path} file for notification"
    else
      rake_puts "no file #{notification_file_path} found"
    end

    lines = File.new(notification_file_path).readlines.map(&:strip)

    lines.each do |line|
      email, *subject = line.split(',')
      subject = *subject.join

      user = User.find_by(email: email)

      body = <<-EOS
      Bonjour,

      Suite à un incident technique concernant les envois d'emails sur le site demarches-simplifiees.fr, nous n'avons pas pu vous remettre l'email intitulé #{subject}.

      Vous pouvez néanmoins le consulter directement dans la messagerie de votre dossier en vous connectant sur https://www.demarches-simplifiees.fr/users/sign_in .

      Veuillez nous excuser pour la gêne occasionnée.

      Cordialement,

      L'équipe de demarches-simplifiees.fr
      EOS

      if user.present?
        rake_puts "sending notification for #{email}"
        ActionMailer::Base.mail(
          from: "contact@demarches-simplifiees.fr",
          to: email,
          subject: subject,
          body: body
        ).deliver_later
      else
        rake_puts "user #{email} does not exist"
      end
    end
  end
end
