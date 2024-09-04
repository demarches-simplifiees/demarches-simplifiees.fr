# frozen_string_literal: true

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

  def self.stable_id_from_typed_id(prefixed_typed_id)
    return nil unless prefixed_typed_id.starts_with?("champ_")

    self.id_from_typed_id(prefixed_typed_id.gsub("champ_", "")).to_i
  rescue
    nil
  end

  def to_typed_id
    GraphQL::Schema::UniqueWithinType.encode(self.class.name, id)
  end

  def to_typed_id_for_query
    to_typed_id.delete("==")
  end
end
