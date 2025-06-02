# frozen_string_literal: true

class BackfillAddEtablissementInfosToServices < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    Service.unscoped.in_batches do |relation| # rubocop:disable DS/Unscoped
      relation.update_all etablissement_infos: {}
      sleep(0.01)
    end
  end
end
