# frozen_string_literal: true

module Types
  class PersonnePhysiqueType < Types::BaseObject
    implements Types::DemandeurType

    field :nom, String, null: false
    field :prenom, String, null: false
    field :civilite, Types::Civilite, null: true, method: :gender
    field :date_de_naissance, GraphQL::Types::ISO8601Date, null: true, method: :birthdate
    field :email, String, "Adresse électronique du bénéficiaire (dans le cas d’un dossier déposé par et pour l’usager connecté, l’adresse électronique est celle de l’usager connecté. Dans le cas d’un dossier déposé pour un bénéficiaire, l’adresse électronique est celle du bénéficiaire, si elle a été renseignée)", null: true
  end
end
