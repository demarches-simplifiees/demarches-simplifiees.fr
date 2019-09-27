module Types
  class PersonneMoraleType < Types::BaseObject
    field :siret, String, null: false
    field :siege_social, String, null: false
    field :naf, String, null: false
    field :libelle_naf, String, null: false
    field :adresse, String, null: false
    field :numero_voie, String, null: false
    field :type_voie, String, null: false
    field :nom_voie, String, null: false
    field :complement_adresse, String, null: false
    field :code_postal, String, null: false
    field :localite, String, null: false
    field :code_insee_localite, String, null: false
  end
end
