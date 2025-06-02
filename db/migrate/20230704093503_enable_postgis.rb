# frozen_string_literal: true

class EnablePostgis < ActiveRecord::Migration[7.0]
  def change
    if ENV['POSTGIS_EXTENSION_DISABLED'] != 'disabled' && ActiveRecord::Base.connection.execute("SELECT 1 as one FROM pg_extension WHERE extname = 'postgis';").count.zero?
      enable_extension :postgis
    end
  end
end
