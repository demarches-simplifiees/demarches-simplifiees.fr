# frozen_string_literal: true

class ExportTemplate::CheckboxComponent < ApplicationComponent
  attr_reader :exported_column, :export_template

  def initialize(export_template:, exported_column:)
    @export_template = export_template
    @exported_column = exported_column
  end

  def call
    safe_join([
      check_box,
      label_tag(label_id, exported_column.libelle),
    ])
  end

  def check_box
    check_box_tag(
      'export_template[exported_columns][]',
      exported_column.id,
      export_template.in_export?(exported_column),
      class: 'fr-checkbox',
      id: sanitize_to_id(label_id), # sanitize_to_id is used by rails in label_tag
      data: { "checkbox-select-all-target": 'checkbox' }
    )
  end

  def label_id
    exported_column.column.id
  end
end
