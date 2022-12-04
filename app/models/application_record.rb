class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.record_from_typed_id(id)
    class_name, record_id = GraphQL::Schema::UniqueWithinType.decode(id)

    if class_name == 'Dossier'
      Dossier.visible_by_administration.find(record_id)
    elsif defined?(class_name)
      Object.const_get(class_name).find(record_id)
    else
      raise ActiveRecord::RecordNotFound, "Unexpected object: #{class_name}"
    end
  rescue => e
    raise ActiveRecord::RecordNotFound, e.message
  end

  def self.id_from_typed_id(id)
    GraphQL::Schema::UniqueWithinType.decode(id)[1]
  end

  def to_typed_id
    GraphQL::Schema::UniqueWithinType.encode(self.class.name, id)
  end

  def event_store
    Rails.configuration.event_store
  end
end
