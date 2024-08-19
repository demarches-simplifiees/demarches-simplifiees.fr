# frozen_string_literal: true

module Maintenance
  class PopulateRNFJSONValueTask < MaintenanceTasks::Task
    include Dry::Monads[:result]

    def collection
      Champs::RNFChamp.where(value_json: nil)
      # Collection to be iterated over
      # Must be Active Record Relation or Array
    end

    def process(champ)
      result = champ.fetch_external_data
      case result
      in Success(data)
        begin
          champ.update_with_external_data!(data:)
        rescue ActiveRecord::RecordInvalid
          # some champ might have dossier nil
        end
      else
        # not found
      end
    end

    def count
      # not really interested in counting because it raises PG Statement timeout
    end
  end
end
