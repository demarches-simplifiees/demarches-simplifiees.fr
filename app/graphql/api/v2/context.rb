class Api::V2::Context < GraphQL::Query::Context
  def has_fragment?(name)
    if self["has_fragment_#{name}"]
      true
    else
      visitor = HasFragment.new(self.query.selected_operation, name)
      visitor.visit
      self["has_fragment_#{name}"] = visitor.found
      self["has_fragment_#{name}"]
    end
  end

  class HasFragment < GraphQL::Language::Visitor
    def initialize(document, name)
      super(document)
      @name = name.to_s
      @found = false
    end

    attr_reader :found

    def on_inline_fragment(node, parent)
      if node.type.name == @name
        @found = true
      end

      super
    end
  end
end
