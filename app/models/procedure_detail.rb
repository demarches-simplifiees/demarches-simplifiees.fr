class ProcedureDetail < OpenStruct
  include SpreadsheetArchitect

  def spreadsheet_columns
    [:id, :libelle, :published_at, :aasm_state, :admin_count].map do |attribute|
      [I18n.t(attribute, scope: 'activerecord.attributes.procedure_export'), attribute]
    end
  end

  def estimated_dossiers_count
    Rails.cache.fetch("procedure_#{self.id}_dossiers_count", expires_in: 1.hour) do
      Procedure.find(id).dossiers.count
    end
  end
end
