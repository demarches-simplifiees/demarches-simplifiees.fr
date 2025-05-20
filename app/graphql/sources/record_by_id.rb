class Sources::RecordById < GraphQL::Dataloader::Source
  def initialize(scope)
    @scope = scope
  end

  def fetch(ids)
    records = @scope.where(id: ids).index_by(&:id)
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
