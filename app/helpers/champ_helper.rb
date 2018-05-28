module ChampHelper
  def is_not_header_nor_explication?(champ)
    !['header_section', 'explication'].include?(champ.type_champ)
  end
end
