# frozen_string_literal: true

module APIParticulier
  module Services
    class BuildData
      def call(raw:)
        data = Hash(raw).deep_symbolize_keys

        {
          caf: caf(**data)
        }
      end

      private

      def caf(**raw)
        famille = raw[:caf]
        return if famille.blank?

        APIParticulier::Entities::CAF::Famille.new(famille)
      end
    end
  end
end
