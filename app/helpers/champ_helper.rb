module ChampHelper
  def has_label?(champ)
    types_without_label = ['header_section', 'explication']
    !types_without_label.include?(champ.type_champ)
  end
end
