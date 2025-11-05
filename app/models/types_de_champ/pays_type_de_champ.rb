# frozen_string_literal: true

class TypesDeChamp::PaysTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def champ_value(champ)
    champ.name
  end

  def champ_value_for_export(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :code
      champ.code
    end
  end

  def champ_value_for_tag(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :code
      champ.code
    end
  end

  def champ_blank?(champ)
    champ.value.blank? && champ.external_id.blank?
  end

  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Code)",
      description: "#{description} (Code)",
      path: :code,
      maybe_null: public? && !mandatory?,
    })
    paths
  end
end
