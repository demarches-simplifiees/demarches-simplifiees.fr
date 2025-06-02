# frozen_string_literal: true

module Types::Champs
  class TitreIdentiteChampType < Types::BaseObject
    implements Types::ChampType

    class TitreIdentiteGrantTypeType < Types::BaseEnum
      value(TypesDeChamp::TitreIdentiteTypeDeChamp::FRANCE_CONNECT, "Françe Connect")
      value(TypesDeChamp::TitreIdentiteTypeDeChamp::PIECE_JUSTIFICATIVE, "Pièce justificative")
    end

    field :grant_type, TitreIdentiteGrantTypeType, null: false
    field :filled, Boolean, null: false

    def grant_type
      TypesDeChamp::TitreIdentiteTypeDeChamp::PIECE_JUSTIFICATIVE
    end

    def filled
      object.piece_justificative_file.attached?
    end
  end
end
