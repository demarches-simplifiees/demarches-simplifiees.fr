module Types::Champs
  class PieceJustificativeChampType < Types::BaseObject
    implements Types::ChampType

    field :file, Types::File, null: true, extensions: [
      { Extensions::Attachment => { attachment: :piece_justificative_file } }
    ]
  end
end
