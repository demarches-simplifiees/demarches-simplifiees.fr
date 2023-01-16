class PrefillDescriptionSerializer < ActiveModel::Serializer
  attributes :$id, :$schema, :title, :type, :properties, :required

  define_method(:$id) { "/preremplir/#{object.path}/schema" }
  define_method(:$schema) { "https://json-schema.org/draft/2020-12/schema" }

  def title
    "JSONSchema description for procedure '#{object.libelle}'"
  end

  def type
    "object"
  end

  def properties
    object.types_de_champ.reduce({}) do |hash, type_de_champ|
      serializer = "JSONSchemaChamps::#{type_de_champ.type_champ.camelize}Serializer".constantize
      hash.update(type_de_champ.to_typed_id => serializer.new(type_de_champ).as_json)
    end
  end

  def required
    object.types_de_champ.filter(&:mandatory).map(&:to_typed_id)
  end
end
