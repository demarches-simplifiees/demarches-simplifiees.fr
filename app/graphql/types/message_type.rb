module Types
  class MessageType < Types::BaseObject
    global_id_field :id
    field :email, String, null: false
    field :body, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :attachment, Types::File, null: true, deprecation_reason: "Utilisez le champ `attachments` à la place.", extensions: [
      { Extensions::Attachment => { attachments: :piece_jointe } }
    ]
    field :attachments, [Types::File], null: false, extensions: [
      { Extensions::Attachment => { attachments: :piece_jointe, as: :multiple } }
    ]
    field :correction, CorrectionType, null: true

    def body
      object.body.nil? ? "" : object.body
    end

    def correction
      Loaders::Association.for(object.class, :dossier_correction).load(object)
    end
  end
end
