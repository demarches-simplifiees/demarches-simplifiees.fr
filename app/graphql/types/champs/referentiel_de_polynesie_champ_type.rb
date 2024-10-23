module Types::Champs
  class ReferentielDePolynesieChampType < Types::BaseObject
    implements Types::ChampType

    field :selected_value, String, null: true
    field :table_id, ID, null: true
    field :search_field, String, null: true

    def selected_value
      object.value
    end

    def table_id
      object.table_id
    end

    def search_field
      object.search_field
    end
  end
end
