module Types::Champs
  class PieceJustificativeChampType < Types::BaseObject
    implements Types::ChampType

    field :file, Types::File, null: true, deprecation_reason: "Utilisez le champ `files` à la place.", extensions: [
      { Extensions::Attachment => { attachments: :piece_justificative_file, flat_first: true } }
    ]

    field :files, [Types::File], null: true, extensions: [
      { Extensions::Attachment => { attachments: :piece_justificative_file } }
    ]
  end
end
