module Types
  class ProfileType < Types::BaseObject
    description "Profil d'un usager connecté (déposant un dossier, instruisant un dossier...)"

    global_id_field :id
    field :email, String, "Email de l'usager", null: false
  end
end
