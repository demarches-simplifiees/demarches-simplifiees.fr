module LexpolFieldsService
  def self.object_field_values(source, field, log_empty: true)
    return [] if source.blank? || field.blank?

    objects = [source]

    field.split('.').each do |segment|
      objects = objects.flat_map do |object|
        if object.is_a?(Champs::RepetitionChamp)
          all_children = object.rows.flatten
          results = select_champ(all_children, segment)
          results += attributes(object, segment) if object.respond_to?(segment)
          results
        else
          results = []
          results = dossier_linked_champs(object) if object.is_a?(Champs::DossierLinkChamp) && object.respond_to?(:dossier)
          results += select_champ(object.champs, segment) if object.respond_to?(:champs)
          results += select_champ(object.annotations, segment) if object.respond_to?(:annotations)
          results += attributes(object, segment) if object.respond_to?(segment)
          results
        end
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

  def self.dossier_linked_champs(object)
    Rails.logger.debug { "Navigating to linked dossier for #{object.inspect}" }
    dossier_linked = Dossier.find_by(id: object.value)
    object.dossier
    dossier_linked ? dossier_linked.champs : []
  end
end
