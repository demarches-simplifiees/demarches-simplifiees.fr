FactoryBot.define do
  factory :virus_scan do
    add_attribute(:status) { VirusScan.statuses.fetch(:pending) }

    trait :pending do
      add_attribute(:status) { VirusScan.statuses.fetch(:pending) }
    end

    trait :safe do
      add_attribute(:status) { VirusScan.statuses.fetch(:safe) }
    end

    trait :infected do
      add_attribute(:status) { VirusScan.statuses.fetch(:infected) }
    end
  end
end
