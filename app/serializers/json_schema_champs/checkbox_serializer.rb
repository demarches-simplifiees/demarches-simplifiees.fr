class JSONSchemaChamps::CheckboxSerializer < ActiveModel::Serializer
  attributes :type, :enum

  def type
    "string"
  end

  def enum
    ["true", "false"]
  end
end
