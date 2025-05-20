class Sources::Association < GraphQL::Dataloader::Source
  def initialize(association_schema)
    @association_schema = association_schema
    @association_name = extract_association_id(association_schema)
  end

  def fetch(records)
    preload_association(records.reject { association_loaded?(_1) })
    records.map { read_association(_1) }
  end

  private

  def read_association(record)
    record.public_send(@association_name)
  end

  def association_loaded?(record)
    record.association(@association_name).loaded?
  end

  def preload_association(records)
    return if records.empty?
    ::ActiveRecord::Associations::Preloader.new(
      records:,
      associations: @association_schema
    ).call
  end

  def extract_association_id(id_or_hash)
    return id_or_hash unless id_or_hash.is_a?(Hash)

    if id_or_hash.keys.size != 1
      raise ArgumentError, "You can only preload exactly one association! You passed: #{id_or_hash}"
    end

    id_or_hash.keys.first
  end
end
