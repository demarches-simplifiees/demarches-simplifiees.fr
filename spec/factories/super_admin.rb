# frozen_string_literal: true

FactoryBot.define do
  sequence(:super_admin_email) { |n| "plop#{n}@plop.com" }
  factory :super_admin do
    email { generate(:super_admin_email) }
    password { '{My-$3cure-p4ssWord}' }
    otp_required_for_login { true }
  end
end
