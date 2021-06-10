module APIParticulier
  module Types
    List = Struct.new(:items) do
      def [](item)
        item.to_s.tap do |i|
          raise ArgumentError, "item: '#{i}' invalid" unless items.include?(i)
        end
      end

      def to_s
        "Types::List(#{items.join(', ')})"
      end
    end

    Enum = Struct.new(:pairs) do
      def [](key)
        k = key.to_s.to_sym
        raise ArgumentError, "key: '#{k}' invalid" unless pairs.keys.include?(k)

        pairs[k]
      end

      def key(value)
        val = value.to_i
        raise ArgumentError, "value: '#{val}' invalid" unless pairs.values.include?(val)

        pairs.key(val)
      end

      def to_s
        "Types::Enum(#{pairs.map { |k, v| "#{k} (#{v})" }.join(', ')})"
      end
    end

    # @see https://api.gouv.fr/documentation/api-particulier
    SEXES = {
      M: "masculin",
      F: "féminin"
    }.freeze

    Sexe = Types::Enum.new(SEXES).freeze

    SCOPES = [
      CAF_SCOPES = ['cnaf_allocataires', 'cnaf_enfants', 'cnaf_adresse', 'cnaf_quotient_familial']
    ].flatten.freeze

    Scope = Types::List.new(SCOPES).freeze
  end
end
