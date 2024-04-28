# frozen_string_literal: true

module Loaders
  class Dossier < GraphQL::Batch::Loader
    def load(key)
      super(key.to_i)
    end

    def perform(keys)
      query(keys).each { |record| fulfill(record.id, record) }
      keys.each { |key| fulfill(key, nil) unless fulfilled?(key) }
    end

    private

    def query(keys)
      ::Dossier.visible_by_administration.for_api_v2.where(id: keys)
    end
  end
end
