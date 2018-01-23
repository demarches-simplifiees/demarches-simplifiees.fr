FactoryBot.define do
  factory :avis do
    introduction 'Bonjour, merci de me donner votre avis sur ce dossier'

    before(:create) do |avis, _evaluator|
      if !avis.gestionnaire
        avis.gestionnaire = create :gestionnaire
      end
    end

    before(:create) do |avis, _evaluator|
      if !avis.dossier
        avis.dossier = create :dossier
      end
    end

    before(:create) do |avis, _evaluator|
      if !avis.claimant
        avis.claimant = create :gestionnaire
      end
    end
  end
end
