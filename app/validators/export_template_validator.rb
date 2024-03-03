class ExportTemplateValidator < ActiveModel::Validator
  def validate(record)
    validate_tiptap_attribute(record, :default_dossier_directory)
    validate_tiptap_attribute(record, :pdf_name)
    validate_pjs(record)
  end

  private
  def validate_tiptap_attribute(record, attribute)
    attribute_content = record.content[attribute.to_s]
    if attribute_content.nil? || attribute_content["content"].nil? ||
        attribute_content["content"].first.nil? ||
        attribute_content["content"].first["content"].nil? ||
        (attribute_content["content"].first["content"].find{|elem| elem["text"].blank? } && attribute_content["content"].first["content"].find{|elem| elem["type"] == "mention"}["attrs"].blank?)
      record.errors.add attribute, 'must not be blank'
    end
  end

  def validate_pjs(record)
    record.content["pjs"].each do |pj|
      pj_sym = pj.symbolize_keys
      validate_content(record, pj_sym[:path], "pj_#{pj_sym[:stable_id]}".to_sym)
    end
  end

  def validate_content(record, attribute_content, attribute)
    if attribute_content.nil? || attribute_content["content"].nil? ||
        attribute_content["content"].first.nil? ||
        attribute_content["content"].first["content"].nil? ||
        (attribute_content["content"].first["content"].find{|elem| elem["text"].blank? } && attribute_content["content"].first["content"].find{|elem| elem["type"] == "mention"}["attrs"].blank?)
      record.errors.add attribute, 'must not be blank'
    end
  end
end
