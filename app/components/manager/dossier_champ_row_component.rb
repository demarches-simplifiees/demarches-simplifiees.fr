# frozen_string_literal: true

class Manager::DossierChampRowComponent < ApplicationComponent
  with_collection_parameter :row

  attr_reader :row

  def initialize(row:)
    @row = row
  end

  def icon
    return unless row.visible?

    if row.mandatory_blank?
      "🔴"
    else
      "🟢"
    end
  end

  def status
    if !row.visible? && row.conditional?
      "masqué, conditionnel"
    elsif row.blank? && !row.piece_justificative_file.attached?
      "vide"
    else
      "rempli"
    end
  end

  def cell_class(cell: nil)
    class_names(
      'cell-data': true,
      'cell-disabled': !row.visible?,
      'pl-8': cell == :label && row.child?
    )
  end

  def nested_rows
    if row.respond_to?(:rows)
      row.rows
    else
      []
    end
  end
end
