# frozen_string_literal: true

# usage DEFAULT_PROCEDURE_EXPIRES_WHEN_TERMINE_ENABLED=true|false rails db:migrate:up VERSION=20220222150340
class SetDefaultProcedureExpiresWhenTermineEnabledToTrue < ActiveRecord::Migration[6.1]
  def up
    change_column :procedures,
                  :procedure_expires_when_termine_enabled,
                  :boolean,
                  default: ENV.fetch('DEFAULT_PROCEDURE_EXPIRES_WHEN_TERMINE_ENABLED') { true }
  end

  def down
    change_column :procedures,
                  :procedure_expires_when_termine_enabled,
                  :boolean,
                  default: false
  end
end
