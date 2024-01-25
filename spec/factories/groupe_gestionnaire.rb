FactoryBot.define do
  factory :groupe_gestionnaire do
    sequence(:name) { |n| "Group #{n}" }
  end
end
