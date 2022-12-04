class ApplicationEvent < RubyEventStore::Event
  module WithSchema
    class Schema < Dry::Struct
      transform_keys(&:to_sym)
    end

    module ClassMethods
      extend Forwardable
      def_delegators :schema, :attribute, :attribute?

      def schema
        @schema ||= Class.new(Schema)
      end
    end

    module Constructor
      def initialize(event_id: SecureRandom.uuid, metadata: nil, data: {})
        super(event_id:, metadata:, data: validate(data))
      end

      private

      def validate(data)
        data.deep_merge(self.class.schema.new(data).to_h)
      end
    end

    def self.included(klass)
      klass.extend WithSchema::ClassMethods
      klass.include WithSchema::Constructor
    end
  end

  include WithSchema
end
