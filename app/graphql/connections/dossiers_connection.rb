# frozen_string_literal: true

module Connections
  class DossiersConnection < CursorConnection
    def initialize(items, lookahead: nil, **kwargs)
      super(items, **kwargs)
      @lookahead = lookahead
    end

    def load_nodes
      if @nodes.nil? && preload?
        DossierPreloader.new(super).all
      else
        super
      end
    end

    private

    def order_column
      arguments[:updated_since].present? ? :updated_at : :depose_at
    end

    def order_table
      :dossiers
    end

    # We check if the query selects champs form dossier. If it's the case we preload the dossier.
    def preload?
      @lookahead.selection(:nodes).selects?(:champs) || @lookahead.selection(:nodes).selects?(:annotations)
    end
  end
end
