FactoryGirl.define do
  factory :commentaire do
    body 'plop'

    before(:create) do |commentaire, _evaluator|
      unless commentaire.dossier
        commentaire.dossier = create :dossier
      end
    end
  end
end
