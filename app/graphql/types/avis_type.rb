module Types
  class AvisType < Types::BaseObject
    global_id_field :id

    field :question, String, null: false, method: :introduction
    field :reponse, String, null: true, method: :answer
    field :date_question, GraphQL::Types::ISO8601DateTime, null: false, method: :created_at
    field :date_reponse, GraphQL::Types::ISO8601DateTime, null: true, method: :updated_at

    field :attachment, Types::File, null: true, extensions: [
      { Extensions::Attachment => { attachment: :piece_justificative_file } }
    ]
    field :instructeur, Types::ProfileType, null: false, method: :claimant, deprecation_reason: "Utilisez le champ claimant à la place."
    field :claimant, Types::ProfileType, null: true
    field :expert, Types::ProfileType, null: true
  end
end
