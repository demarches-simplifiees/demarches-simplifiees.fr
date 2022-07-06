module Types
  class BaseField < GraphQL::Schema::Field
    def initialize(*args, internal: false, **kwargs, &block)
      @internal = internal
      super(*args, **kwargs, &block)
    end

    def visible?(ctx)
      super && (@internal ? ctx[:internal_use] : true)
    end
  end
end
