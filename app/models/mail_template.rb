class MailTemplate < ActiveRecord::Base
  belongs_to :procedure

  enum balises: {
           numero_dossier: {
               attr: 'dossier.id',
               description: "Permet d'afficher le numéro de dossier de l'utilisateur."
           }
       }
end
