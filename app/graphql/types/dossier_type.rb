module Types
  class DossierType < Types::BaseObject
    class DossierState < Types::BaseEnum
      Dossier.aasm.states.reject { |state| state.name == :brouillon }.each do |state|
        value(state.name.to_s, Dossier.human_attribute_name("state.#{state.name}"), value: state.name.to_s)
      end
    end

    description "Un dossier"

    global_id_field :id
    field :number, Int, "Le numero du dossier.", null: false, method: :id
    field :state, DossierState, "L’état du dossier.", null: false

    field :demarche, Types::DemarcheDescriptorType, null: false, method: :revision

    field :date_depot, GraphQL::Types::ISO8601DateTime, "Date de dépôt.", null: false, method: :depose_at
    field :date_passage_en_construction, GraphQL::Types::ISO8601DateTime, "Date du dernier passage en construction.", null: false, method: :en_construction_at
    field :date_passage_en_instruction, GraphQL::Types::ISO8601DateTime, "Date du dernier passage en instruction.", null: true, method: :en_instruction_at
    field :date_traitement, GraphQL::Types::ISO8601DateTime, "Date du dernier traitement.", null: true, method: :processed_at
    field :date_derniere_modification, GraphQL::Types::ISO8601DateTime, "Date de la dernière modification.", null: false, method: :updated_at

    field :date_suppression_par_usager, GraphQL::Types::ISO8601DateTime, "Date de la suppression par l’usager.", null: true, method: :hidden_by_user_at
    field :date_suppression_par_administration, GraphQL::Types::ISO8601DateTime, "Date de la suppression par l’administration.", null: true, method: :hidden_by_administration_at
    field :date_expiration, GraphQL::Types::ISO8601DateTime, "Date d’expiration.", null: true

    field :archived, Boolean, null: false

    field :motivation, String, null: true
    field :motivation_attachment, Types::File, null: true, extensions: [
      { Extensions::Attachment => { attachment: :justificatif_motivation } }
    ]

    field :pdf, Types::File, "L’URL du dossier au format PDF.", null: true
    field :geojson, Types::File, "L’URL du GeoJSON contenant les données cartographiques du dossier.", null: true
    field :attestation, Types::File, "L’URL de l’attestation au format PDF.", null: true

    field :usager, Types::ProfileType, null: false
    field :groupe_instructeur, Types::GroupeInstructeurType, null: false
    field :revision, Types::RevisionType, null: false, deprecation_reason: 'Utilisez le champ `demarche.revision` à la place.'

    field :demandeur, Types::DemandeurType, null: false

    field :instructeurs, [Types::ProfileType], null: false

    field :messages, [Types::MessageType], null: false do
      argument :id, ID, required: false
    end
    field :avis, [Types::AvisType], null: false do
      argument :id, ID, required: false
    end
    field :champs, [Types::ChampType], null: false do
      argument :id, ID, required: false
    end
    field :annotations, [Types::ChampType], null: false do
      argument :id, ID, required: false
    end
    field :traitements, [Types::TraitementType], null: false

    def state
      object.state
    end

    def date_expiration
      if !object.en_instruction?
        object.expiration_date
      end
    end

    def usager
      if object.user_deleted?
        { email: object.user_email_for(:display), id: '<deleted>' }
      else
        Loaders::Record.for(User).load(object.user_id)
      end
    end

    def groupe_instructeur
      Loaders::Record.for(GroupeInstructeur, includes: [:procedure]).load(object.groupe_instructeur_id)
    end

    def demandeur
      if object.revision.procedure.for_individual
        Loaders::Association.for(object.class, :individual).load(object)
      else
        Loaders::Association.for(object.class, :etablissement).load(object)
      end
    end

    def instructeurs
      Loaders::Association.for(object.class, :followers_instructeurs).load(object)
    end

    def traitements
      Loaders::Association.for(object.class, :traitements).load(object)
    end

    def messages(id: nil)
      if id.present?
        Loaders::Record
          .for(Commentaire, where: { dossier: object }, includes: [:instructeur, :expert], array: true)
          .load(ApplicationRecord.id_from_typed_id(id))
      else
        Loaders::Association.for(object.class, commentaires: [:instructeur, :expert]).load(object)
      end
    end

    def avis(id: nil)
      if id.present?
        Loaders::Record
          .for(Avis, where: { dossier: object }, includes: [:expert, :claimant], array: true)
          .load(ApplicationRecord.id_from_typed_id(id))
      else
        Loaders::Association.for(object.class, avis: [:expert, :claimant]).load(object)
      end
    end

    def champs(id: nil)
      if id.present?
        Loaders::Champ
          .for(object, private: false)
          .load(ApplicationRecord.id_from_typed_id(id))
      else
        Loaders::Association
          .for(object.class, champs_public: :type_de_champ)
          .load(object)
          .then { |champs| champs.filter(&:visible?) }
      end
    end

    def annotations(id: nil)
      if id.present?
        Loaders::Champ
          .for(object, private: true)
          .load(ApplicationRecord.id_from_typed_id(id))
      else
        Loaders::Association.for(object.class, champs_private: :type_de_champ).load(object)
      end
    end

    def pdf
      sgid = object.to_sgid(expires_in: 1.hour, for: 'api_v2')
      {
        filename: "dossier-#{object.id}.pdf",
        content_type: 'application/pdf',
        url: Rails.application.routes.url_helpers.api_v2_dossier_pdf_url(id: sgid)
      }
    end

    def geojson
      sgid = object.to_sgid(expires_in: 1.hour, for: 'api_v2')
      {
        filename: "dossier-#{object.id}-features.json",
        content_type: 'application/json',
        url: Rails.application.routes.url_helpers.api_v2_dossier_geojson_url(id: sgid)
      }
    end

    def attestation
      if object.termine? && object.attestation_template&.activated?
        Loaders::Association.for(object.class, attestation: { pdf_attachment: :blob })
          .load(object)
          .then { |attestation| attestation&.pdf }
      end
    end

    def self.authorized?(object, context)
      context.authorized_demarche?(object.revision.procedure)
    end
  end
end
