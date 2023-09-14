# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  row_id                         :string
#  type_de_champ_id               :integer
#
class Champs::NumeroDnChamp < Champ
  store_accessor :value_json, :numero_dn, :date_de_naissance

  validates_with NumeroDnValidator, if: -> { validation_context != :brouillon }

  def numero_dn=(value)
    value = value.to_s.rjust(7, "0") if value.present?
    super(value)
  end

  def date_de_naissance=(value)
    value = begin
      Time.zone.parse(value).to_date.iso8601
            rescue
              nil
    end
    pack_value(numero_dn, value)
    super(value)
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
      ''
    end
  end

  def for_export
    value.present? ? "#{numero_dn || ''};#{displayed_date_de_naissance || ''}" : nil
  end

  def for_api
    value.present? ? { numero_dn: numero_dn, date_de_naissance: date_de_naissance } : nil
  end

  def blank?
    value.blank?
  end

  def search_terms
    [numero_dn, date_de_naissance]
  end

  private

  def pack_value(numero_dn, date_de_naissance)
    self.value = numero_dn.blank? || date_de_naissance.blank? ? nil : JSON.generate([numero_dn, date_de_naissance])
  end
end
