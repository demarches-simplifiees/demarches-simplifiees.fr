# frozen_string_literal: true

module AddressHelper
  def address_array(champ)
    scope = "activemodel.attributes.normalized_address"
    address = AddressProxy.new(champ)

    [
      [t("full_address", scope:), full_address(address)],
      [t("city_code", scope:), address.city_code],
      [t("postal_code", scope:), address.postal_code],
      [t("department", scope:), address.departement_name],
      [t("region", scope:), address.region_name]
    ]
  end

  private

  def full_address(proxy)
    safe_join([
      proxy.street_address,
      [proxy.city_name, proxy.postal_code].join(" ")
    ], tag.br)
  end
end
