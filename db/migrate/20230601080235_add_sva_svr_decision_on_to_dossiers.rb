# frozen_string_literal: true

class AddSVASVRDecisionOnToDossiers < ActiveRecord::Migration[7.0]
  def change
    add_column :dossiers, :sva_svr_decision_on, :date, default: nil
    add_column :dossiers, :sva_svr_decision_triggered_at, :datetime, default: nil
  end
end
