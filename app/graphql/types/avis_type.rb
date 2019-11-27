module Types
  class AvisType < Types::BaseObject
    global_id_field :id

    field :question, String, null: false, method: :introduction
    field :reponse, String, null: true, method: :answer
    field :date_question, GraphQL::Types::ISO8601DateTime, null: false, method: :created_at
    field :date_reponse, GraphQL::Types::ISO8601DateTime, null: true, method: :updated_at

    field :attachment_url, Types::URL, null: true, extensions: [
      { Extensions::Attachment => { attachment: :piece_justificative_file } }
    ]

    field :instructeur, Types::ProfileType, null: false, method: :claimant
    field :expert, Types::ProfileType, null: true, method: :instructeur
  end
end
