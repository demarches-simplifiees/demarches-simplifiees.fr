# frozen_string_literal: true

class TypesDeChamp::PoleEmploiTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def champ_blank?(champ) = champ.external_id.blank?
end
