class Champs::YesNoChamp < Champs::CheckboxChamp
  private

  def value_for_export
    value == 'true' ? 'oui' : 'non'
  end
end
