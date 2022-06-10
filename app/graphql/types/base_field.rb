module Types
  class BaseField < GraphQL::Schema::Field
    def initialize(*args, require_admin: false, **kwargs, &block)
      @require_admin = require_admin
      super(*args, **kwargs, &block)
    end

    def visible?(ctx)
      super && (@require_admin ? ctx[:admin] : true)
    end
  end
end
