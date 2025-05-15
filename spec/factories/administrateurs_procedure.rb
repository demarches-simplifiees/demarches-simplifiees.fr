FactoryBot.define do
  factory :administrateurs_procedure do
    administrateur { Administrateur.find_by(user: { email: "default_admin@admin.com" }) }
    association :procedure
  end
end
