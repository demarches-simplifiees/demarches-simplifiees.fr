# frozen_string_literal: true

require Rails.root.join("app/types/column_type")
require Rails.root.join("app/types/export_item_type")
require Rails.root.join("app/types/sorted_column_type")
require Rails.root.join("app/types/filtered_column_type")
require Rails.root.join("app/types/exported_column_type")

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Type.register(:column, ColumnType)
  ActiveRecord::Type.register(:export_item, ExportItemType)
  ActiveRecord::Type.register(:sorted_column, SortedColumnType)
  ActiveRecord::Type.register(:filtered_column, FilteredColumnType)
  ActiveRecord::Type.register(:exported_column, ExportedColumnType)
end
