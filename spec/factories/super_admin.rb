FactoryBot.define do
  sequence(:super_admin_email) { |n| "plop#{n}@plop.com" }
  factory :super_admin do
    email { generate(:super_admin_email) }
    password { 'my-s3cure-p4ssword' }
    otp_required_for_login { true }
  end
end
