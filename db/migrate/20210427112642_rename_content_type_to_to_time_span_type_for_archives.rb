# frozen_string_literal: true

class RenameContentTypeToToTimeSpanTypeForArchives < ActiveRecord::Migration[6.1]
  def change
    rename_column :archives, :content_type, :time_span_type
  end
end
