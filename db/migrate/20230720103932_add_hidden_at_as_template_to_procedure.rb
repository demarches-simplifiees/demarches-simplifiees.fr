# frozen_string_literal: true

class AddHiddenAtAsTemplateToProcedure < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :hidden_at_as_template, :datetime
  end
end
