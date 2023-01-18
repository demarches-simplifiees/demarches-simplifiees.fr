class API::V2::Context < GraphQL::Query::Context
  # This method is used to check if a given fragment is used in the given query.
  # We need that in order to maintain backward compatibility for Types de Champ
  # that we extended in later iterations of our schema.
  def has_fragment?(fragment_name)
    self[:has_fragment] ||= Hash.new do |hash, fragment_name|
      visitor = HasFragment.new(query.document, fragment_name)
      visitor.visit
      hash[fragment_name] = visitor.found
    end
    self[:has_fragment][fragment_name]
  end

  def internal_use?
    self[:internal_use]
  end

  def current_administrateur
    unless self[:administrateur_id]
      raise GraphQL::ExecutionError.new("Pour effectuer cette opération, vous avez besoin d’un jeton au nouveau format. Vous pouvez l’obtenir dans votre interface administrateur.", extensions: { code: :deprecated_token })
    end
    Administrateur.find(self[:administrateur_id])
  end

  def authorized_demarche?(demarche, opendata: false)
    if internal_use?
      return true
    end

    if opendata && demarche.opendata?
      return true
    end

    # We are caching authorization logic because it is called for each node
    # of the requested graph and can be expensive. Context is reset per request so it is safe.
    self[:authorized] ||= Hash.new do |hash, demarche_id|
      hash[demarche_id] = if self[:token]
        APIToken.find_and_verify(self[:token], demarche.administrateurs).present?
      elsif self[:administrateur_id]
        demarche.administrateurs.map(&:id).include?(self[:administrateur_id])
      end
    end

    self[:authorized][demarche.id]
  end

  # This is a query AST visitor that we use to check
  # if a fragment with a given name is used in the given document.
  # We check for both inline and standalone fragments.
  class HasFragment < GraphQL::Language::Visitor
    def initialize(document, fragment_name)
      super(document)
      @fragment_name = fragment_name.to_s
      @found = false
    end

    attr_reader :found

    def on_inline_fragment(node, parent)
      if node.type.name == @fragment_name
        @found = true
      end

      super
    end

    def on_fragment_definition(node, parent)
      if node.type.name == @fragment_name
        @found = true
      end

      super
    end
  end
end
