FactoryBot.define do
  factory :admins_group do
    sequence(:name) { |n| "Group #{n}" }
  end
end
