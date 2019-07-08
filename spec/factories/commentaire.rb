FactoryBot.define do
  factory :commentaire do
    body { 'plop' }

    before(:create) do |commentaire, _evaluator|
      if !commentaire.dossier
        commentaire.dossier = create :dossier, :en_construction
      end
    end
  end
end
