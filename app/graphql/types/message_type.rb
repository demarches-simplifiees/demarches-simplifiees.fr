module Types
  class MessageType < Types::BaseObject
    global_id_field :id
    field :email, String, null: false
    field :body, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :attachment_url, Types::URL, null: true, extensions: [
      { Extensions::Attachment => { attachment: :piece_jointe } }
    ]

    def body
      object.body.nil? ? "" : object.body
    end
  end
end
