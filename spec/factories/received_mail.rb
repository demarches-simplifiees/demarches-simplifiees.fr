FactoryGirl.define do
  factory :received_mail, class: Mails::ReceivedMail do
    object "Mail d'accusé de bonne reception de votre dossier"
    body "Votre dossier est correctement reçu"
  end
end
