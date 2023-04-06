module Types
  class MessageType < Types::BaseObject
    global_id_field :id
    field :email, String, null: false
    field :body, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :attachment, Types::File, null: true, deprecation_reason: "Utilisez le champ `attachments` à la place.", extensions: [
      { Extensions::Attachment => { attachment: :piece_jointe } }
    ]
    field :attachments, [Types::File], null: false, extensions: [
      { Extensions::Attachment => { attachment: :piece_jointe, as: :multiple } }
    ]

    def body
      object.body.nil? ? "" : object.body
    end
  end
end
