FactoryBot.define do
  factory :commentaire_groupe_gestionnaire do
    association :groupe_gestionnaire

    body { 'plop' }
  end
end
