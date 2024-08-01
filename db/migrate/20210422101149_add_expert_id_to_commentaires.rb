# frozen_string_literal: true

class AddExpertIdToCommentaires < ActiveRecord::Migration[6.1]
  def change
    add_belongs_to :commentaires, :expert, type: :bigint, foreign_key: true
  end
end
