namespace :'2018_08_24_encrypt_tokens' do
  task run: :environment do
    Administrateur
      .where
      .not(api_token: nil)
      .each do |admin|
      admin.update(encrypted_token: BCrypt::Password.create(admin.api_token))
    end
  end
end
