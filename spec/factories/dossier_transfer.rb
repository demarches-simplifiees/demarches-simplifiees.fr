FactoryBot.define do
  factory :dossier_transfer do
    email { generate(:user_email) }
  end
end
