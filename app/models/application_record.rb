class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.record_from_typed_id(id)
    class_name, record_id = GraphQL::Schema::UniqueWithinType.decode(id)

    if defined?(class_name)
      Object.const_get(class_name).find(record_id)
    else
      raise ActiveRecord::RecordNotFound, "Unexpected object: #{class_name}"
    end
  rescue => e
    raise ActiveRecord::RecordNotFound, e.message
  end

  def to_typed_id
    GraphQL::Schema::UniqueWithinType.encode(self.class.name, id)
  end
end
