module LexpolFieldsService
  def self.object_field_values(source, field, log_empty: true)
    return [] if source.blank? || field.blank?

    objects = [*source]

    field.split('.').each do |segment|
      objects = objects.flat_map do |object|
        object = object.dossier if object.respond_to?(:dossier)
        results = []
        results += select_champ(object.champs, segment) if object.respond_to?(:champs)
        results += select_champ(object.annotations, segment) if object.respond_to?(:annotations)
        results += attributes(object, segment) if object.respond_to?(segment)

        results
      end

      if log_empty && objects.blank?
        Rails.logger.warn("Dans LexpolFieldsService, le champ '#{field}' est vide après '#{segment}'.")
      end
    end

    objects
  end

  def self.select_champ(collection, name)
    return [] if collection.blank?

    collection.filter do |c|
      c.type_de_champ&.libelle == name
    end
  end

  def self.attributes(object, name)
    value = object.send(name)
    value.is_a?(Array) ? value : [value].compact
  end
end
