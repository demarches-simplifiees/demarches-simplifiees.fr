FactoryBot.define do
  factory :zone do
    sequence(:acronym) { |n| "MA#{n}" }
    sequence(:label) { |n| "Ministère de l'Education Populaire #{n}" }
  end
end
