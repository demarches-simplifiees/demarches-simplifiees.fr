module Types::Champs
  class PieceJustificativeChampType < Types::BaseObject
    include Rails.application.routes.url_helpers
    implements Types::ChampType

    field :url, Types::URL, null: true, extensions: [
      { Extensions::Attachment => { attachment: :piece_justificative_file } }
    ]
  end
end
