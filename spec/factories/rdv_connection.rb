# frozen_string_literal: true

FactoryBot.define do
  factory :rdv_connection do
    access_token { "access_token" }
    refresh_token { "refresh_token" }
    expires_at { 1.day.from_now }
  end
end
