# frozen_string_literal: true

class DropVirusScanTable < ActiveRecord::Migration[7.0]
  def up
    drop_table :virus_scans
  end
end
