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

    trait :dossier_en_instruction do
      object "[TPS] Accusé de réception pour votre dossier nº --numero_dossier--"
      body "Votre administration vous confirme la bonne réception de votre dossier nº --numero_dossier--"
      type 'MailReceived'
    end
  end
end
