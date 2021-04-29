# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  row                            :integer
#  type                           :string
#  value                          :string
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::AddressChamp < Champs::TextChamp
  def full_address?
    data.present?
  end

  def address
    full_address? ? data : nil
  end

  def address_label
    full_address? ? data['label'] : value
  end

  def search_terms
    if full_address?
      [data['label'], data['departement'], data['region'], data['city']]
    else
      [address_label]
    end
  end

  def to_s
    address_label
  end

  def for_tag
    address_label
  end

  def for_export
    value.present? ? address_label : nil
  end

  def for_api
    address_label
  end

  def fetch_external_data?
    true
  end

  def fetch_external_data
    APIAddress::AddressAdapter.new(external_id).to_params
  end
end
