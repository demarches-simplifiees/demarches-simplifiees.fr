# frozen_string_literal: true

# references:
# https://github.com/Shopify/graphql-batch/blob/master/examples/association_loader.rb
# https://gist.github.com/palkan/03eb5306a1a3e8addbe8df97a298a466
# https://evilmartians.com/chronicles/active-storage-meets-graphql-pt-2-exposing-attachment-urls

module Loaders
  class Association < GraphQL::Batch::Loader
    def self.validate(model, association_name)
      new(model, association_name)
      nil
    end

    def initialize(model, association_schema)
      @model = model
      @association_schema = association_schema
      @association_name = extract_association_id(association_schema)
      validate
    end

    def load(record)
      raise TypeError, "#{@model} loader can't load association for #{record.class}" unless record.is_a?(@model)
      return Promise.resolve(read_association(record)) if association_loaded?(record)
      super
    end

    # We want to load the associations on all records, even if they have the same id
    def cache_key(record)
      record.object_id
    end

    def perform(records)
      preload_association(records.uniq)
      records.each { |record| fulfill(record, read_association(record)) }
    end

    private

    def validate
      unless @model.reflect_on_association(@association_name)
        raise ArgumentError, "No association #{@association_name} on #{@model}"
      end
    end

    def preload_association(records)
      ::ActiveRecord::Associations::Preloader.new(
        records: records,
        associations: @association_schema
      ).call
    end

    def read_association(record)
      record.public_send(@association_name)
    end

    def association_loaded?(record)
      record.association(@association_name).loaded?
    end

    def extract_association_id(id_or_hash)
      return id_or_hash unless id_or_hash.is_a?(Hash)

      if id_or_hash.keys.size != 1
        raise ArgumentError, "You can only preload exactly one association! You passed: #{id_or_hash}"
      end

      id_or_hash.keys.first
    end
  end
end
