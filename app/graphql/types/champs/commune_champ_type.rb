module Types::Champs
  class CommuneChampType < Types::BaseObject
    implements Types::ChampType

    class CommuneType < Types::BaseObject
      field :name, String, null: false
      field :code, String, "Le code INSEE", null: false
    end

    field :commune, CommuneType, null: true
    field :departement, Types::Champs::DepartementChampType::DepartementType, null: true

    def commune
      if object.code?
        {
          name: object.to_s,
          code: object.code
        }
      end
    end

    def departement
      if object.departement?
        {
          name: object.name_departement,
          code: object.code_departement
        }
      end
    end
  end
end
