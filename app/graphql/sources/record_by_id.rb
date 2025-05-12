class Sources::RecordById < GraphQL::Dataloader::Source
  def initialize(scope, where: -> (ids) { { id: ids } }, index_by: -> (record) { record.id })
    @scope = scope
    @where = where
    @index_by = index_by
  end

  def fetch(ids)
    records = @scope.where(@where.(ids)).index_by { @index_by.(_1) }
    ids.map { records[_1.to_i] }
  end

  def self.batch_key_for(scope, _ = nil)
    if scope.is_a?(ActiveRecord::Relation)
      scope.to_sql
    else
      scope.name
    end
  end
end
