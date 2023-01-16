class JSONSchemaChamps::DateSerializer < ActiveModel::Serializer
  attributes :type, :format

  def type
    "string"
  end

  def format
    "date"
  end
end
