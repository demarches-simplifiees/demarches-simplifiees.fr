module Types::Champs
  class RNFChampType < Types::BaseObject
    implements Types::ChampType

    class RNFType < Types::BaseObject
      field :id, String, null: false
      field :title, String, null: true
      field :address, Types::AddressType, null: true

      def id
        object.value
      end

      def title
        object.data["title"]
      end

      def address
        address = object.data["address"]
        if address
          {
            label: address["label"],
            type: address["type"],
            street_address: address["streetAddress"],
            street_number: address["streetNumber"],
            street_name: address["streetName"],
            postal_code: address["postalCode"],
            city_name: address["cityName"],
            city_code: address["cityCode"],
            department_name: address["departmentName"],
            department_code: address["departmentCode"],
            region_name: address["regionName"],
            region_code: address["regionCode"]
          }
        end
      end
    end

    field :rnf, RNFType, null: true

    def rnf
      object if object.external_id.present?
    end
  end
end
