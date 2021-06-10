# frozen_string_literal: true

module APIParticulier
  module Entities
    module Sanitizable
      module InstanceMethods
        def as_sanitized_json(mask = nil)
          mask ||= {}
          as_json.symbolize_keys.reject { |k, _| mask.fetch(k, 0) == 0 }
        end

        def <=>(other)
          as_json <=> other.as_json
        end
      end

      def self.included(receiver)
        receiver.include Comparable
        receiver.include InstanceMethods
      end
    end
  end
end
