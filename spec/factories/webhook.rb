FactoryBot.define do
  factory :webhook do
    association :procedure
    label { 'My webhook' }
    url { 'https://test.test/test' }
    event_type { [:dossier_depose] }
  end
end
