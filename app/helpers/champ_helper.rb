module ChampHelper
  def format_text_value(text)
    sanitized_text = sanitize(text)
    auto_linked_text = Anchored::Linker.auto_link(sanitized_text, target: '_blank', rel: 'noopener') do |link_href|
      truncate(link_href, length: 60)
    end
    sanitized_text.gsub!(/ (\S{15})/, ' \1') if sanitized_text.present? # unbreakable space breaks layout
    simple_format(auto_linked_text, {}, sanitize: false)
  end

  def auto_attach_url(object, params = {})
    if object.is_a?(Champ)
      if Champ.update_by_stable_id?
        champs_piece_justificative_url(object.dossier, object.stable_id, params.merge(row_id: object.row_id))
      else
        champs_legacy_piece_justificative_url(object.id, params)
      end
    elsif object.is_a?(TypeDeChamp) && object.piece_justificative?
      piece_justificative_template_admin_procedure_type_de_champ_url(stable_id: object.stable_id, procedure_id: object.procedure.id, **params)
    elsif object.is_a?(TypeDeChamp) && object.explication?
      notice_explicative_admin_procedure_type_de_champ_url(stable_id: object.stable_id, procedure_id: object.procedure.id, **params)
    end
  end
end
