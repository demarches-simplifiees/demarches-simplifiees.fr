class JSONSchemaChamps::TextSerializer < ActiveModel::Serializer
  attributes :type

  def type
    "string"
  end
end
