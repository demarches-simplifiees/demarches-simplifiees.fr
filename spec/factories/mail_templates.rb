FactoryBot.define do
  factory :closed_mail, class: Mails::ClosedMail do
    subject { "Subject, voila voila" }
    body { "Blabla ceci est mon body" }

    factory :received_mail, class: Mails::ReceivedMail

    factory :refused_mail, class: Mails::RefusedMail

    factory :without_continuation_mail, class: Mails::WithoutContinuationMail

    factory :initiated_mail, class: Mails::InitiatedMail do
      subject { "[#{SITE_NAME}] Accusé de réception pour votre dossier nº --numéro du dossier--" }
      body { "Votre administration vous confirme la bonne réception de votre dossier nº --numéro du dossier--" }
    end
  end
end
