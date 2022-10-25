module ChampHelper
  def format_text_value(text)
    sanitized_text = sanitize(text)
    auto_linked_text = Anchored::Linker.auto_link(sanitized_text, target: '_blank', rel: 'noopener') do |link_href|
      truncate(link_href, length: 60)
    end
    simple_format(auto_linked_text, {}, sanitize: false)
  end

  def auto_attach_url(object, url_options = {})
    if object.is_a?(Champ)
      champs_piece_justificative_url(object.id, url_options)
    elsif object.is_a?(TypeDeChamp)
      piece_justificative_template_admin_procedure_type_de_champ_url(stable_id: object.stable_id, procedure_id: object.procedure.id)
    end
  end
end
