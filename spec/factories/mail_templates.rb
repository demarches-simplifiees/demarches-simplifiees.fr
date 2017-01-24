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
      object "[TPS] Accusé de réception pour votre dossier n°--numero_dossier--"
      body "Votre administration vous confirme la bonne réception de votre dossier n°--numero_dossier--"
      type 'MailReceived'
    end
  end
end
