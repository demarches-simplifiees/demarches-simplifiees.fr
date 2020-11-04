FactoryBot.define do
  sequence(:administration_email) { |n| "plop#{n}@plop.com" }
  factory :administration do
    email { generate(:administration_email) }
    password { 'my-s3cure-p4ssword' }
    otp_required_for_login { true }
  end
end
