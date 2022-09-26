FactoryBot.define do
  factory :zone do
    sequence(:acronym) { |n| "MA#{n}" }
    transient do
      labels { [{ designated_on: '1981-05-08', name: "Ministère de l'Education Populaire" }] }
    end

    after(:create) do |zone, evaluator|
      evaluator.labels.each do |label|
        zone.labels.create(designated_on: label[:designated_on], name: label[:name])
      end
    end
  end
end
