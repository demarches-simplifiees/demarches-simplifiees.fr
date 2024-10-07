# frozen_string_literal: true

require Rails.root.join("app/types/column_type")
require Rails.root.join("app/types/export_item_type")

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Type.register(:column, ColumnType)
  ActiveRecord::Type.register(:export_item, ExportItemType)
end
