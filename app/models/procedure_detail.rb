class ProcedureDetail < OpenStruct
  include SpreadsheetArchitect

  def spreadsheet_columns
    [:id, :libelle, :published_at, :aasm_state, :admin_count].map do |attribute|
      [I18n.t(attribute, scope: 'activerecord.attributes.procedure_export'), attribute]
    end
  end
end
