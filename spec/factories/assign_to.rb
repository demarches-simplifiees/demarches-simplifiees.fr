FactoryBot.define do
  factory :assign_to do
    after(:build) do |assign_to, _evaluator|
      assign_to.groupe_instructeur = assign_to.procedure.defaut_groupe_instructeur
    end
  end
end
