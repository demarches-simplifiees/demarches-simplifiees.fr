FactoryBot.define do
  factory :france_connect_information do
    given_name { 'Angela Claire Louise' }
    family_name { 'DUBOIS' }
    gender { 'female' }
    birthdate { '1976-02-24' }
    france_connect_particulier_id { '1234567' }
    email_france_connect { 'plip@octo.com' }
  end
end
