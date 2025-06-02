# frozen_string_literal: true

FactoryBot.define do
  factory :release_note do
    body { "Sample release note body" }
    categories { ReleaseNote::CATEGORIES.sample(1) }
    published { true }
    released_on { 1.day.ago.to_date }
  end
end
