module Types
  class AvisType < Types::BaseObject
    global_id_field :id
    field :email, String, null: false
    field :question, String, null: false, method: :introduction
    field :answer, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :attachment_url, Types::URL, null: true, extensions: [
      { Extensions::Attachment => { attachment: :piece_justificative_file } }
    ]
  end
end
