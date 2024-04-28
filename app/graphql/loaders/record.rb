# frozen_string_literal: true

# references:
# https://github.com/Shopify/graphql-batch/blob/master/examples/record_loader.rb

module Loaders
  class Record < GraphQL::Batch::Loader
    def initialize(model, column: model.primary_key, where: nil, includes: nil, array: false)
      @model = model
      @column = column.to_s
      @column_type = model.type_for_attribute(@column)
      @where = where
      @includes = includes
      @array = array
    end

    def load(key)
      super(@column_type.cast(key))
    end

    def perform(keys)
      query(keys).each do |record|
        fulfilled_value = @array ? [record].compact : record
        fulfill(record.public_send(@column), fulfilled_value)
      end
      keys.each { |key| fulfill(key, @array ? [] : nil) unless fulfilled?(key) }
    end

    private

    def query(keys)
      scope = @model
      scope = scope.where(@where) if @where
      scope = scope.includes(@includes) if @includes
      scope.where(@column => keys)
    end
  end
end
