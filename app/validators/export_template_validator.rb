class ExportTemplateValidator < ActiveModel::Validator
  def validate(record)
    validate_default_dossier_directory(record)
    validate_pdf_name(record)
    validate_pjs(record)
  end

  private

  def validate_default_dossier_directory(record)
    mention = attribute_content_mention(record, :default_dossier_directory)
    if mention&.fetch("id", nil) != "dossier_number"
      record.errors.add :tiptap_default_dossier_directory, :dossier_number_mandatory
    end
  end

  def validate_pdf_name(record)
    if attribute_content_text(record, :pdf_name).blank? && attribute_content_mention(record, :pdf_name).blank?
      record.errors.add :tiptap_pdf_name, :blank
    end
  end

  def attribute_content_text(record, attribute)
    attribute_content(record, attribute)&.find { |elem| elem["type"] == "text" }&.fetch("text", nil)
  end

  def attribute_content_mention(record, attribute)
    attribute_content(record, attribute)&.find { |elem| elem["type"] == "mention" }&.fetch("attrs", nil)
  end

  def attribute_content(record, attribute)
    content = record.content[attribute.to_s]&.fetch("content", nil)
    if content.is_a?(Array)
      content.first&.fetch("content", nil)
    end
  end

  def validate_pjs(record)
    record.content["pjs"]&.each do |pj|
      pj_sym = pj.symbolize_keys
      libelle = record.groupe_instructeur.procedure.exportables_pieces_jointes.find { _1.stable_id.to_s == pj_sym[:stable_id] }&.libelle&.to_sym
      validate_content(record, pj_sym[:path], libelle)
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
