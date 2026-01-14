# frozen_string_literal: true

module Maintenance
  # Nettoie les valeurs de cadre_juridique qui contiennent des données invalides
  # (balises HTML, …)
  # Les données legacy légitimes (numéros de décret, références légales) sont préservées
  class T20251210CleanCadreJuridiqueTask < MaintenanceTasks::Task
    PATTERNS = [
      /<.+>/i, # Balises HTML (<a>, etc.)
      /&#60;/,                             # Entités HTML encodées (&#60; = <)
      /&#x3c;;/i,                          # Entités HTML hex (&#x3c; = <)
      /\Ajavascript:/i,                    # Schéma javascript:
      /\Adata:/i,                          # Schéma data:
      /\Avbscript:/i,                      # Schéma vbscript:
    ].freeze

    def collection
      Procedure.where.not(cadre_juridique: [nil, ''])
    end

    def process(procedure)
      return unless invalid_value?(procedure.cadre_juridique)

      Rails.logger.info("Cleaning cadre_juridique for procedure #{procedure.id}, original value: #{procedure.cadre_juridique}")
      procedure.update_column(:cadre_juridique, nil)
    end

    def count
      collection.count
    end

    private

    def invalid_value?(value)
      return false if value.blank?

      PATTERNS.any? { |pattern| value.match?(pattern) }
    end
  end
end
