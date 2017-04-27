FactoryGirl.define do
  factory :avis do
    introduction 'Bonjour, merci de me donner votre avis sur ce dossier'

    before(:create) do |avis, _evaluator|
      unless avis.gestionnaire
        avis.gestionnaire = create :gestionnaire
      end
    end

    before(:create) do |avis, _evaluator|
      unless avis.dossier
        avis.dossier = create :dossier
      end
    end
  end
end
