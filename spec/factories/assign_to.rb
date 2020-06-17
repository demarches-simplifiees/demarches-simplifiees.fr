FactoryBot.define do
  factory :assign_to do
    after(:build) do |assign_to, evaluator|
      if evaluator.groupe_instructeur.persisted?
        assign_to.groupe_instructeur = evaluator.groupe_instructeur
      else
        assign_to.groupe_instructeur = assign_to.procedure.defaut_groupe_instructeur
      end
    end
  end
end
