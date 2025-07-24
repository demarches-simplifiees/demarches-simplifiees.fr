# frozen_string_literal: true

FactoryBot.define do
  factory :closed_mail, class: Mails::ClosedMail do
    subject { "Subject, voila voila" }
    body { "Blabla ceci est mon body" }
    association :procedure

    factory :received_mail, class: Mails::ReceivedMail

    factory :refused_mail, class: Mails::RefusedMail

    factory :re_instructed_mail, class: Mails::ReInstructedMail

    factory :without_continuation_mail, class: Mails::WithoutContinuationMail

    factory :initiated_mail, class: Mails::InitiatedMail do
      subject { "[demarches-simplifiees.fr] Accusé de réception pour votre dossier n° --numéro du dossier--" }
      body { "Votre administration vous confirme la bonne réception de votre dossier n° --numéro du dossier--" }
    end
  end
end
