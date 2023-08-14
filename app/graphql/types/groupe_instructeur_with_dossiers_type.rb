module Types
  class GroupeInstructeurWithDossiersType < GroupeInstructeurType
    description "Un groupe instructeur avec ses dossiers"

    field :dossiers, Types::DossierType.connection_type, "Liste de tous les dossiers d’un groupe instructeur.", null: false, extras: [:lookahead] do
      argument :order, Types::Order, default_value: :asc, required: false, description: "L’ordre des dossiers."
      argument :created_since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers déposés depuis la date."
      argument :updated_since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers mis à jour depuis la date."
      argument :state, Types::DossierType::DossierState, required: false, description: "Dossiers avec statut."
      argument :archived, Boolean, required: false, description: "Seulement les dossiers archivés."
      argument :revision, ID, required: false, description: "Seulement les dossiers pour la révision donnée."
      argument :max_revision, ID, required: false, description: "Seulement les dossiers pour les révisons avant la révision donnée."
      argument :min_revision, ID, required: false, description: "Seulement les dossiers pour les révisons après la révision donnée."
    end

    field :deleted_dossiers, Types::DeletedDossierType.connection_type, "Liste de tous les dossiers supprimés d’un groupe instructeur.", null: false do
      argument :order, Types::Order, default_value: :asc, required: false, description: "L’ordre des dossiers supprimés."
      argument :deleted_since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers supprimés depuis la date."
    end

    field :pending_deleted_dossiers, Types::DeletedDossierType.connection_type, "Liste de tous les dossiers en attente de suppression définitive d’un groupe instructeur.", null: false do
      argument :order, Types::Order, default_value: :asc, required: false, description: "L’ordre des dossiers en attente de suppression."
      argument :deleted_since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers en attente de suppression depuis la date."
    end

    def dossiers(updated_since: nil, created_since: nil, state: nil, archived: nil, revision: nil, max_revision: nil, min_revision: nil, order:, lookahead:)
      dossiers = object
        .dossiers
        .visible_by_administration
        .for_api_v2

      if state.present?
        dossiers = dossiers.where(state: state)
      end

      if !archived.nil?
        dossiers = dossiers.where(archived: archived)
      end

      if !revision.nil?
        dossiers = dossiers.where(revision: find_revision(revision))
      else
        if !min_revision.nil?
          dossiers = dossiers.joins(:revision).where('procedure_revisions.created_at >= ?', find_revision(min_revision).created_at)
        end

        if !max_revision.nil?
          dossiers = dossiers.joins(:revision).where('procedure_revisions.created_at <= ?', find_revision(max_revision).created_at)
        end
      end

      if updated_since.present?
        dossiers = dossiers.updated_since(updated_since).order_by_updated_at(order)
      else
        if created_since.present?
          dossiers = dossiers.created_since(created_since)
        end

        dossiers = dossiers.order_by_created_at(order)
      end

      # We wrap dossiers in a custom connection alongsite the lookahead for the query.
      # The custom connection is responsible for preloading paginated dossiers.
      # https://graphql-ruby.org/pagination/custom_connections.html#using-a-custom-connection
      # https://graphql-ruby.org/queries/lookahead.html
      Connections::DossiersConnection.new(dossiers, lookahead: lookahead)
    end

    def deleted_dossiers(deleted_since: nil, order:)
      dossiers = object.deleted_dossiers

      if deleted_since.present?
        dossiers = dossiers.deleted_since(deleted_since)
      end

      dossiers.order(deleted_at: order)
    end

    def pending_deleted_dossiers(deleted_since: nil, order:)
      dossiers = object.dossiers.hidden_for_administration

      if deleted_since.present?
        dossiers = dossiers.hidden_since(deleted_since)
      end

      dossiers.order(hidden_by_user_at: order, hidden_by_administration_at: order)
    end
  end
end
