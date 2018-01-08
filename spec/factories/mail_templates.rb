FactoryGirl.define do
  factory :mail_template, class: Mails::ClosedMail do
    object "Object, voila voila"
    body "Blabla ceci est mon body"

    factory :dossier_submitted_mail_template, class: Mails::ReceivedMail

    factory :dossier_refused_mail_template, class: Mails::RefusedMail

    factory :dossier_en_instruction_mail_template, class: Mails::InitiatedMail do
      object "[TPS] Accusé de réception pour votre dossier nº --numéro du dossier--"
      body "Votre administration vous confirme la bonne réception de votre dossier nº --numéro du dossier--"
    end
  end
end
