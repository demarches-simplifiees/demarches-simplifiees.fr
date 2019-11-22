module Types
  class DossierType < Types::BaseObject
    class DossierState < Types::BaseEnum
      Dossier.aasm.states.reject { |state| state.name == :brouillon }.each do |state|
        value(state.name.to_s, state.display_name, value: state.name.to_s)
      end
    end

    description "Un dossier"

    global_id_field :id
    field :number, Int, "Le numero du dossier.", null: false, method: :id
    field :state, DossierState, "L'état du dossier.", null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, "Date de dernière mise à jour.", null: false

    field :date_passage_en_construction, GraphQL::Types::ISO8601DateTime, "Date de dépôt.", null: false, method: :en_construction_at
    field :date_passage_en_instruction, GraphQL::Types::ISO8601DateTime, "Date de passage en instruction.", null: true, method: :en_instruction_at
    field :date_traitement, GraphQL::Types::ISO8601DateTime, "Date de traitement.", null: true, method: :processed_at

    field :archived, Boolean, null: false

    field :motivation, String, null: true
    field :motivation_attachment_url, Types::URL, null: true, extensions: [
      { Extensions::Attachment => { attachment: :justificatif_motivation } }
    ]

    field :usager, Types::ProfileType, null: false
    field :instructeurs, [Types::ProfileType], null: false

    field :champs, [Types::ChampType], null: false
    field :annotations, [Types::ChampType], null: false

    field :messages, [Types::MessageType], null: false
    field :avis, [Types::AvisType], null: false

    def state
      object.state
    end

    def usager
      Loaders::Record.for(User).load(object.user_id)
    end

    def instructeurs
      Loaders::Association.for(object.class, :followers_instructeurs).load(object)
    end

    def messages
      Loaders::Association.for(object.class, commentaires: [:instructeur, :user]).load(object)
    end

    def avis
      Loaders::Association.for(object.class, avis: [:instructeur, :claimant]).load(object)
    end

    def champs
      Loaders::Association.for(object.class, :champs).load(object)
    end

    def annotations
      Loaders::Association.for(object.class, :champs_private).load(object)
    end

    def self.authorized?(object, context)
      authorized_demarche?(object.procedure, context)
    end
  end
end
