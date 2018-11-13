namespace :'activate_trusted_device_for_a-f' do
  task run: :environment do
    letters_a_to_f = ('a'..'f').to_a
    Gestionnaire
      .where("substr(email, 1, 1) IN (?)", letters_a_to_f)
      .update_all(features: { "enable_email_login_token" => true })
  end
end
