# frozen_string_literal: true

class TypesDeChamp::AddressTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  include AddressableColumnConcern

  def libelles_for_export
    path = paths.first
    [[path[:libelle], path[:path]]]
  end

  def champ_value(champ)
    champ.address_label.presence || ''
  end

  def champ_value_for_api(champ, version: 2)
    champ_value(champ)
  end

  def champ_value_for_tag(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :departement
      champ.departement_code_and_name || ''
    when :commune
      champ.commune_name || ''
    end
  end

  def champ_value_for_export(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :departement
      champ.departement_code_and_name
    when :commune
      champ.commune_name
    end
  end

  def champ_blank?(champ)
    if champ.migrated_legacy_address?
      champ.value.blank?
    else
      !champ.full_address?
    end
  end

  def champ_blank_or_invalid?(champ)
    return true if champ.migrated_legacy_address? && champ.value.blank?
    if champ.not_ban? && champ.france?
      # Pour les adresses manuelles françaises, on vérifie que les deux champs sont remplis
      champ.street_address.blank? || champ.commune_name.blank?
    elsif champ.international?
      # Pour les adresses internationales, tous les champs doivent être remplis
      champ.street_address.blank? || champ.city_name.blank? || champ.postal_code.blank?
    else
      # Pour les adresses BAN, on utilise la méthode existante
      !champ.full_address?
    end
  end

  def mandatory_blank?(champ)
    return nil if champ.migrated_legacy_address? && champ.value.present?
    return [:value, :missing] if champ.migrated_legacy_address? && champ.value.blank?

    if champ.not_ban? && champ.france?
      if champ.street_address.blank? && champ.commune_name.blank?
        [:value, :missing]
      elsif champ.street_address.blank?
        [:street_address, :required]
      elsif champ.commune_name.blank?
        [:commune_name, :required]
      else
        nil
      end
    elsif champ.international?
      # Retourner le premier champ manquant
      if champ.street_address.blank?
        [:street_address, :required]
      elsif champ.city_name.blank?
        [:city_name, :required]
      elsif champ.postal_code.blank?
        [:postal_code, :required]
      else
        nil
      end
    else
      # Pour les adresses BAN
      champ.full_address? ? nil : [:value, :missing]
    end
  end

  def columns(procedure:, displayable: true, prefix: nil)
    super
      .concat(addressable_columns(procedure:, displayable:, prefix:))
  end

  def info_columns(procedure:)
    Dossiers::AddressComponent.data_labels
  end

  private

  def paths
    paths = super
    paths.push(
      {
        libelle: "#{libelle} (Département)",
        path: :departement,
        description: "#{description} (Département)",
      },
      {
        libelle: "#{libelle} (Commune)",
        path: :commune,
        description: "#{description} (Commune)",
      }
    )
    paths
  end
end
