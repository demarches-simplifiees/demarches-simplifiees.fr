# frozen_string_literal: true

FactoryBot.define do
  factory :contact_form do
    user { nil }
    email { 'test@example.com' }
    dossier_id { nil }
    subject { 'Test Subject' }
    text { 'Test Content' }
    question_type { 'lost_user' }
    tags { ['test tag'] }
    phone { nil }
  end
end
