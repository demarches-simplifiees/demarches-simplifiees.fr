class ProcedurePresentation < ApplicationRecord
  belongs_to :assign_to

  def displayed_fields
    read_attribute(:displayed_fields).map do |field|
      field = JSON.parse(field)
    end
  end

  def sort
    JSON.parse(read_attribute(:sort))
  end

  def filters
    JSON.parse(read_attribute(:filters))
  end
end
