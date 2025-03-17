module HeaderSectionsHelper
  module_function

  def anchor_id_for_header(header)
    "type_de_champ_editor_champ_#{header.id}"
  end
end
