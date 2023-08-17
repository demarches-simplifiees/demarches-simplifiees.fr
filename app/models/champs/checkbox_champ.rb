class Champs::CheckboxChamp < Champs::BooleanChamp
  def dsfr_champ_container
    :fieldset
  end

  def for_export
    true? ? 'on' : 'off'
  end

  def mandatory_blank?
    mandatory? && (blank? || !true?)
  end

  def legend_label?
    false
  end

  def html_label?
    false
  end

  def single_checkbox?
    true
  end
end
