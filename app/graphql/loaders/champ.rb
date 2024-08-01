# frozen_string_literal: true

# references:
# https://github.com/Shopify/graphql-batch/blob/master/examples/record_loader.rb

module Loaders
  class Champ < GraphQL::Batch::Loader
    def initialize(dossier, private: false)
      @where = { dossier: dossier, private: private }
    end

    def load(key)
      super(key.to_i)
    end

    def perform(keys)
      query(keys).each { |record| fulfill(record.stable_id, [record].compact) }
      keys.each { |key| fulfill(key, []) unless fulfilled?(key) }
    end

    private

    def query(keys)
      ::Champ.where(@where).where(stable_id: keys)
    end
  end
end
