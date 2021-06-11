FactoryBot.define do
  factory :france_connect_information do
    given_name { 'Angela Claire Louise' }
    family_name { 'DUBOIS' }
    gender { 'female' }
    birthdate { Date.new(1962, 8, 24) }
    france_connect_particulier_id { 'b6048e95bb134ec5b1d1e1fa69f287172e91722b9354d637a1bcf2ebb0fd2ef5v1' }
    email_france_connect { 'wossewodda-3728@yopmail.com' }

    trait :with_user do
      user { build(:user, email: email_france_connect) }
    end
  end
end
