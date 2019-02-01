class Champs::CheckboxChamp < Champs::YesNoChamp
  def true?
    value == 'on'
  end

  def for_export
    true? ? 'on' : 'off'
  end
end
