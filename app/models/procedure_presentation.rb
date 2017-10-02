class ProcedurePresentation < ActiveRecord::Base
  belongs_to :assign_to

  def displayed_fields
    read_attribute(:displayed_fields).map do |field|
      field = JSON.parse(field)
    end
  end
end
