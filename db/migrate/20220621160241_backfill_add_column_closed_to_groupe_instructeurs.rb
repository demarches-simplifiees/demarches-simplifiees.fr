# frozen_string_literal: true

class BackfillAddColumnClosedToGroupeInstructeurs < ActiveRecord::Migration[6.1]
  def up
    GroupeInstructeur.in_batches do |relation|
      relation.update_all closed: false
      sleep(0.01)
    end
  end
end
