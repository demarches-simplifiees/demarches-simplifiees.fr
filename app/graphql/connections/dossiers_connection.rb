module Connections
  class DossiersConnection < GraphQL::Pagination::ActiveRecordRelationConnection
    def initialize(items, lookahead: nil, **kwargs)
      super(items, **kwargs)
      @lookahead = lookahead
    end

    def nodes
      if @nodes.nil? && preload?
        DossierPreloader.new(super).all
      else
        super
      end
    end

    private

    # We check if the query selects champs form dossier. If it's the case we preload the dossier.
    def preload?
      @lookahead.selection(:nodes).selects?(:champs) || @lookahead.selection(:nodes).selects?(:annotations)
    end
  end
end
