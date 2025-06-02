# frozen_string_literal: true

class Champs::NumeroDnChamp < Champ
  store_accessor :value_json, :numero_dn, :date_de_naissance

  validates_with NumeroDnValidator, if: :validate_champ_value?

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
    blank? ? "" : "#{for_tag(:value)} né(e) le #{for_tag(:date_de_naissance)}"
  end

  def blank?
    value.blank?
  end

  def search_terms
    [numero_dn, displayed_date_de_naissance]
  end

  private

  def pack_value(numero_dn, date_de_naissance)
    self.value = numero_dn.blank? || date_de_naissance.blank? ? nil : JSON.generate([numero_dn, date_de_naissance])
  end
end
