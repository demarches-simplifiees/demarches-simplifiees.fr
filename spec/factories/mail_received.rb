FactoryGirl.define do
  factory :mail_received do
    object "Mail d'accusé de bonne reception de votre dossier"
    body "Votre dossier est correctement reçu"
    type 'MailReceived'
  end
end
