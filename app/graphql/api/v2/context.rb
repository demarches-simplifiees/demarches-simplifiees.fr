class API::V2::Context < GraphQL::Query::Context
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

  def internal_use?
    self[:internal_use]
  end

  def authorized_demarche?(demarche)
    if internal_use?
      return true
    end

    # We are caching authorization logic because it is called for each node
    # of the requested graph and can be expensive. Context is reset per request so it is safe.
    self[:authorized] ||= Hash.new do |hash, demarche_id|
      # Compute the hash value dynamically when first requested
      authorized_administrateur = demarche.administrateurs.find do |administrateur|
        if self[:token]
          administrateur.valid_api_token?(self[:token])
        else
          administrateur.id == self[:administrateur_id]
        end
      end
      hash[demarche_id] = authorized_administrateur.present?
    end

    self[:authorized][demarche.id]
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
