class Notification < ActiveRecord::Base
  belongs_to :dossier

  enum type_notif: {
           commentaire: 'commentaire'
       }

end
