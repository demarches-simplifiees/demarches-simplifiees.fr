FactoryGirl.define do
  factory :mail_template do
    object "Object, voila voila"
    body "Blabla ceci est mon body"
    type 'MailValidated'

    trait :dossier_submitted do
      type 'MailSubmitted'
    end

    trait :dossier_refused do
      type 'MailRefused'
    end

    trait :dossier_received do
      type 'MailReceived'
    end
  end
end
