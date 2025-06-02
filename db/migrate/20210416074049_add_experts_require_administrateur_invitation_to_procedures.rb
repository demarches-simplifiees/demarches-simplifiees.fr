# frozen_string_literal: true

class AddExpertsRequireAdministrateurInvitationToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :experts_require_administrateur_invitation, :boolean, default: false
  end
end
