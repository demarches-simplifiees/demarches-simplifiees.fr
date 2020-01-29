module Types
  class PersonneMoraleType < Types::BaseObject
    class EntrepriseType < Types::BaseObject
      field :siren, String, null: false
      field :capital_social, GraphQL::Types::BigInt, null: false
      field :numero_tva_intracommunautaire, String, null: false
      field :forme_juridique, String, null: false
      field :forme_juridique_code, String, null: false
      field :nom_commercial, String, null: false
      field :raison_sociale, String, null: false
      field :siret_siege_social, String, null: false
      field :code_effectif_entreprise, String, null: false
      field :date_creation, GraphQL::Types::ISO8601Date, null: false
      field :nom, String, null: false
      field :prenom, String, null: false
      field :inline_adresse, String, null: false
    end

    class AssociationType < Types::BaseObject
      field :rna, String, null: false
      field :titre, String, null: false
      field :objet, String, null: false
      field :date_creation, GraphQL::Types::ISO8601Date, null: false
      field :date_declaration, GraphQL::Types::ISO8601Date, null: false
      field :date_publication, GraphQL::Types::ISO8601Date, null: false
    end

    implements Types::DemandeurType

    field :siret, String, null: false
    field :siege_social, Boolean, null: false
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
    field :entreprise, EntrepriseType, null: true
    field :association, AssociationType, null: true

    def entreprise
      if object.entreprise_siren.present?
        object.entreprise
      end
    end

    def association
      if object.association?
        {
          rna: object.association_rna,
          titre: object.association_titre,
          objet: object.association_objet,
          date_creation: object.association_date_creation,
          date_declaration: object.association_date_declaration,
          date_publication: object.association_date_publication
        }
      end
    end
  end
end
