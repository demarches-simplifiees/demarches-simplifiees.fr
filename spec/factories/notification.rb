FactoryGirl.define do
  factory :notification do
    type_notif 'commentaire'
    liste []

    before(:create) do |notification, _evaluator|
      unless notification.dossier
        notification.dossier = create :dossier
      end
    end
  end
end
