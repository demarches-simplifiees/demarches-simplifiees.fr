class ExportTemplateValidator < ActiveModel::Validator
  def validate(record)
    validate_dossier_folder(record)
    validate_export_pdf(record)
    validate_pjs(record)
  end

  private

  def validate_dossier_folder(record)
    content = record.dossier_folder['content']&.first&.fetch('content', nil)
    mention = attribute_content_mention(content)
    if mention&.fetch("id", nil) != "dossier_number"
      record.errors.add :dossier_folder, :dossier_number_mandatory
    end
  end

  def validate_export_pdf(record)
    content = record.export_pdf['template']['content']&.first&.fetch('content', nil)
    if attribute_content_text(content).blank? && attribute_content_mention(content).blank?
      record.errors.add :export_pdf, :blank
    end
  end

  def attribute_content_text(content)
    content&.find { |elem| elem["type"] == "text" }&.fetch("text", nil)
  end

  def attribute_content_mention(content)
    content&.find { |elem| elem["type"] == "mention" }&.fetch("attrs", nil)
  end

  def validate_pjs(record)
    record.pjs.each do |pj|
      pj_sym = pj.symbolize_keys
      libelle = record.groupe_instructeur.procedure.exportables_pieces_jointes.find { _1.stable_id.to_s == pj_sym[:stable_id] }&.libelle
      validate_content(record, pj_sym[:template], libelle)
    end
  end

  def validate_content(record, attribute_content, attribute)
    if attribute_content.nil? || attribute_content["content"].nil? ||
        attribute_content["content"].first.nil? ||
        attribute_content["content"].first["content"].nil? ||
        (attribute_content["content"].first["content"].find { |elem| elem["text"].blank? } && attribute_content["content"].first["content"].find { |elem| elem["type"] == "mention" }["attrs"].blank?)
      record.errors.add attribute, I18n.t(:blank, scope: 'errors.messages')
    end
  end
end
