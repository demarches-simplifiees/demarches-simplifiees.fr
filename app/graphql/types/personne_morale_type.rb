module Types
  class PersonneMoraleType < Types::BaseObject
    class EntrepriseType < Types::BaseObject
      class EffectifType < Types::BaseObject
        field :periode, String, null: false
        field :nb, Float, null: false
      end

      class EntrepriseEtatAdministratifType < Types::BaseEnum
        value("Actif", "L'entreprise est en activité", value: Etablissement.entreprise_etat_administratifs.fetch("actif"))
        value("Ferme", "L'entreprise a cessé son activité", value: Etablissement.entreprise_etat_administratifs.fetch("fermé"))
      end

      field :siren, String, null: false
      field :capital_social, GraphQL::Types::BigInt, null: true, description: "capital social de l’entreprise. -1 si inconnu."
      field :numero_tva_intracommunautaire, String, null: true
      field :forme_juridique, String, null: true
      field :forme_juridique_code, String, null: true
      field :nom_commercial, String, null: false
      field :raison_sociale, String, null: false
      field :siret_siege_social, String, null: false
      field :code_effectif_entreprise, String, null: true
      field :effectif_mensuel, EffectifType, null: true, description: "effectif pour un mois donné"
      field :effectif_annuel, EffectifType, null: true, description: "effectif moyen d’une année"
      field :date_creation, GraphQL::Types::ISO8601Date, null: true
      field :etat_administratif, EntrepriseEtatAdministratifType, null: true
      field :nom, String, null: true
      field :prenom, String, null: true
      field :inline_adresse, String, null: false
      field :attestation_sociale_attachment, Types::File, null: true
      field :attestation_fiscale_attachment, Types::File, null: true

      def attestation_sociale_attachment
        load_attachment_for(:entreprise_attestation_sociale_attachment)
      end

      def attestation_fiscale_attachment
        load_attachment_for(:entreprise_attestation_fiscale_attachment)
      end

      def effectif_mensuel
        if object.effectif_mensuel.present?
          {
            periode: [object.effectif_mois, object.effectif_annee].join('/'),
            nb: object.effectif_mensuel
          }
        end
      end

      def capital_social
        # capital_social is defined as a BigInt, so we can't return an empty string when value is unknown
        # 0 could appear to be a legitimate value, so a negative value helps to ensure the value is not known
        object.capital_social || '-1'
      end

      def code_effectif_entreprise
        # we need this in order to bypass Hashie::Dash deserialization issue on nil values
        object.code_effectif_entreprise
      end

      def effectif_annuel
        if object.effectif_annuel.present?
          {
            periode: object.effectif_annuel_annee,
            nb: object.effectif_annuel
          }
        end
      end

      private

      def load_attachment_for(key)
        Loaders::Association.for(
          Etablissement,
          key => :blob
        ).load(object.etablissement)
      end
    end

    class AssociationType < Types::BaseObject
      field :rna, String, null: false
      field :titre, String, null: false
      field :objet, String, null: true
      field :date_creation, GraphQL::Types::ISO8601Date, null: true
      field :date_declaration, GraphQL::Types::ISO8601Date, null: true
      field :date_publication, GraphQL::Types::ISO8601Date, null: true
    end

    implements Types::DemandeurType

    field :siret, String, null: false
    field :siege_social, Boolean, null: false
    field :naf, String, null: true # see: https://sentry.io/organizations/demarches-simplifiees/issues/2839832517/activity/?environment=production&project=1429550&query=is%3Aunresolved&referrer=issue-stream#
    field :libelle_naf, String, null: false

    field :address, Types::AddressType, null: false

    field :entreprise, EntrepriseType, null: true
    field :association, AssociationType, null: true

    field :adresse, String, null: false, deprecation_reason: "Utilisez le champ `address.label` à la place."
    field :numero_voie, String, null: true, deprecation_reason: "Utilisez le champ `address.street_number` à la place."
    field :type_voie, String, null: true, deprecation_reason: "Utilisez le champ `address.street_address` à la place."
    field :nom_voie, String, null: true, deprecation_reason: "Utilisez le champ `address.street_name` à la place."
    field :code_postal, String, null: false, deprecation_reason: "Utilisez le champ `address.postal_code` à la place."
    field :localite, String, null: false, deprecation_reason: "Utilisez le champ `address.city_name` à la place."
    field :code_insee_localite, String, null: false, deprecation_reason: "Utilisez le champ `address.city_code` à la place."
    field :complement_adresse, String, null: true, deprecation_reason: "Utilisez le champ `address` à la place."

    def address
      {
        label: object.adresse,
        type: "housenumber",
        street_number: object.numero_voie,
        street_name: object.nom_voie,
        street_address: object.nom_voie.present? ? [object.numero_voie, object.type_voie, object.nom_voie].compact.join(' ') : nil,
        postal_code: object.code_postal.presence || '',
        city_name: object.localite.presence || '',
        city_code: object.code_insee_localite.presence || ''
      }
    end

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
