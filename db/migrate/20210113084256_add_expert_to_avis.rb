class AddExpertToAvis < ActiveRecord::Migration[6.0]
  def change
    add_reference :avis, :expert, foreign_key: true
  end
end
