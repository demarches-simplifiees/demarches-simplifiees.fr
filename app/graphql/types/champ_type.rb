module Types
  module ChampType
    include Types::BaseInterface

    global_id_field :id
    field :champ_descriptor_id, String, "L'identifiant du champDescriptor de ce champ", null: false
    field :label, String, "Libellé du champ.", null: false, method: :libelle
    field :string_value, String, "La valeur du champ sous forme texte.", null: true, method: :for_api_v2
    field :updated_at, GraphQL::Types::ISO8601DateTime, "Date de dernière modification du champ.", null: false
    field :prefilled, Boolean, null: false, method: :prefilled?

    definition_methods do
      def resolve_type(object, context)
        case object
        when ::Champs::AddressChamp
          if context.has_fragment?(:AddressChamp)
            Types::Champs::AddressChampType
          else
            Types::Champs::TextChampType
          end
        when ::Champs::YesNoChamp, ::Champs::CheckboxChamp
          Types::Champs::CheckboxChampType
        when ::Champs::DateChamp
          Types::Champs::DateChampType
        when ::Champs::DatetimeChamp
          if context.has_fragment?(:DatetimeChamp)
            Types::Champs::DatetimeChampType
          else
            Types::Champs::DateChampType
          end
        when ::Champs::CommuneChamp
          if context.has_fragment?(:CommuneChamp)
            Types::Champs::CommuneChampType
          else
            Types::Champs::TextChampType
          end
        when ::Champs::CommuneDePolynesieChamp
          if context.has_fragment?(:CommuneDePolynesieChamp)
            Types::Champs::CommuneDePolynesieChampType
          else
            Types::Champs::TextChampType
          end
        when ::Champs::CodePostalDePolynesieChamp
          if context.has_fragment?(:CommuneDePolynesieChamp)
            Types::Champs::CodePostalDePolynesieChampType
          else
            Types::Champs::TextChampType
          end
        when ::Champs::DepartementChamp
          if context.has_fragment?(:DepartementChamp)
            Types::Champs::DepartementChampType
          else
            Types::Champs::TextChampType
          end
        when ::Champs::RegionChamp
          if context.has_fragment?(:RegionChamp)
            Types::Champs::RegionChampType
          else
            Types::Champs::TextChampType
          end
        when ::Champs::PaysChamp
          if context.has_fragment?(:PaysChamp)
            Types::Champs::PaysChampType
          else
            Types::Champs::TextChampType
          end
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
        when ::Champs::TitreIdentiteChamp
          Types::Champs::TitreIdentiteChampType
        when ::Champs::VisaChamp
          Types::Champs::VisaChampType
        when ::Champs::ReferentielDePolynesieChamp
          Types::Champs::ReferentielDePolynesieChampType
        when ::Champs::EpciChamp
          Types::Champs::EpciChampType
        when ::Champs::RNAChamp
          Types::Champs::RNAChampType
        when ::Champs::RNFChamp
          Types::Champs::RNFChampType
        when ::Champs::EngagementJuridiqueChamp
          Types::Champs::EngagementJuridiqueChampType
        else
          Types::Champs::TextChampType
        end
      end
    end
  end
end
