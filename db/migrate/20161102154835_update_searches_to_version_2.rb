class UpdateSearchesToVersion2 < ActiveRecord::Migration
  def up
    replace_view :searches, version: 2 unless Rails.env.test?
  end

  def down
    replace_view :searches, version: 1 unless Rails.env.test?
  end
end
