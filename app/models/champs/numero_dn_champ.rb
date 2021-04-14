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
class Champs::NumeroDnChamp < Champ
  validates_with NumeroDnValidator

  def numero_dn
    if value.present?
      values[0]
    else
      ''
    end
  end

  def date_de_naissance
    tab = values
    tab.present? ? tab[1] : nil
  end

  def numero_dn=(value)
    value = value.to_s.rjust(7, "0") if value.present?
    pack_value(value, date_de_naissance)
  end

  def date_de_naissance=(value)
    value = begin
              Time.zone.parse(value).to_date.iso8601
            rescue
              nil
            end
    pack_value(numero_dn, value)
  end

  def displayed_date_de_naissance
    ddn = date_de_naissance
    ddn.present? ? Date.parse(ddn).strftime('%d/%m/%Y') : ''
  end

  def to_s
    for_tag
  end

  def for_tag
    if value.present?
      "#{numero_dn || ''}#{(ddn = displayed_date_de_naissance).present? ? " né(e) le #{ddn}" : ''}"
    else
      nil
    end
  end

  def for_export
    value.present? ? "#{numero_dn || ''};#{displayed_date_de_naissance || ''}" : nil
  end

  def for_api
    value.present? ? { numero_dn: numero_dn, date_de_naissance: date_de_naissance } : nil
  end

  def blank?
    value.blank? || values.any?(&:blank?)
  end

  def search_terms
    values
  end

  private

  def values
    value.present? ? JSON.parse(value) : nil
  end

  def pack_value(numero_dn, date_de_naissance)
    self.value = JSON.generate([numero_dn, date_de_naissance])
  end
end
