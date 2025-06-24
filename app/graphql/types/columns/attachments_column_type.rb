# frozen_string_literal: true

module Types::Columns
  class AttachmentsColumnType < Types::BaseObject
    implements Types::ColumnType

    field :value, [Types::File], null: true, extras: [:parent]

    def value(parent:)
      Loaders::Association.for(Champ, piece_justificative_file_attachments: :blob)
        .load(parent)
        .then { object.value(parent) }
    end
  end
end
