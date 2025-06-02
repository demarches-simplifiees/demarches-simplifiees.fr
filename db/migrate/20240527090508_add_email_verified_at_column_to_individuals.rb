# frozen_string_literal: true

class AddEmailVerifiedAtColumnToIndividuals < ActiveRecord::Migration[7.0]
  def change
    add_column :individuals, :email_verified_at, :datetime
  end
end
