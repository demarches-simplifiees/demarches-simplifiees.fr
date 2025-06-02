# frozen_string_literal: true

module Connections
  class DeletedDossiersConnection < CursorConnection
    private

    def order_column
      :deleted_at
    end

    def order_table
      :deleted_dossiers
    end
  end
end
