module Types
  module ChampType
    include Types::BaseInterface

    global_id_field :id
    field :label, String, "Libellé du champ.", null: false, method: :libelle
    field :string_value, String, "La valeur du champ sous forme texte.", null: true, method: :for_api_v2

    definition_methods do
      def resolve_type(object, context)
        case object
        when ::Champs::EngagementChamp, ::Champs::YesNoChamp, ::Champs::CheckboxChamp
          Types::Champs::CheckboxChampType
        when ::Champs::DateChamp, ::Champs::DatetimeChamp
          Types::Champs::DateChampType
        when ::Champs::DossierLinkChamp
          Types::Champs::DossierLinkChampType
        when ::Champs::PieceJustificativeChamp
          Types::Champs::PieceJustificativeChampType
        when ::Champs::CarteChamp
          Types::Champs::CarteChampType
        when ::Champs::NumberChamp, ::Champs::IntegerNumberChamp
          Types::Champs::IntegerNumberChampType
        when ::Champs::DecimalNumberChamp
          Types::Champs::DecimalNumberChampType
        when ::Champs::SiretChamp
          Types::Champs::SiretChampType
        when ::Champs::RepetitionChamp
          Types::Champs::RepetitionChampType
        when ::Champs::MultipleDropDownListChamp
          Types::Champs::MultipleDropDownListChampType
        when ::Champs::LinkedDropDownListChamp
          Types::Champs::LinkedDropDownListChampType
        when ::Champs::NumeroDnChamp
          Types::Champs::NumeroDnChampType
        when ::Champs::CiviliteChamp
          Types::Champs::CiviliteChampType
        else
          Types::Champs::TextChampType
        end
      end
    end
  end
end
