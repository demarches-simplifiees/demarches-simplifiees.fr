# frozen_string_literal: true

module Types
  class MessageType < Types::BaseObject
    global_id_field :id
    field :email, String, null: false
    field :body, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :discarded_at, GraphQL::Types::ISO8601DateTime, null: true
    field :attachment, Types::File, null: true, deprecation_reason: "Utilisez le champ `attachments` à la place.", extensions: [
      { Extensions::Attachment => { attachments: :piece_jointe, as: :single } }
    ]
    field :attachments, [Types::File], null: false, extensions: [
      { Extensions::Attachment => { attachments: :piece_jointe } }
    ]
    field :correction, CorrectionType, null: true

    def body
      object.body.nil? ? "" : object.body
    end

    def correction
      dataloader.with(Sources::Association, :dossier_correction).load(object)
    end

    def self.authorized?(object, context)
      context.authorized_demarche?(object.dossier.revision.procedure)
    end
  end
end
