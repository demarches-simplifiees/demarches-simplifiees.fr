# frozen_string_literal: true

class TypesDeChamp::MesriTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def champ_value_blank?(champ)
    champ.external_id.blank?
  end
end
