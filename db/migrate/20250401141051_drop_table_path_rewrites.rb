# frozen_string_literal: true

class DropTablePathRewrites < ActiveRecord::Migration[7.0]
  def change
    drop_table :path_rewrites
  end
end
