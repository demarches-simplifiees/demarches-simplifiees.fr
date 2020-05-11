module Types::Champs
  class NumeroDnChampType < Types::BaseObject
    implements Types::ChampType

    field :numero_dn, String, "Le numero DN sur 7 chiffres", null: true
    field :date_de_naissance, GraphQL::Types::ISO8601Date, "La date de naissance associée", null: true

    def date_de_naissance
      ddn = object.date_de_naissance
      if ddn.present?
        Date.parse(ddn)
      end
    end
  end
end
