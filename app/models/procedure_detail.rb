ProcedureDetail = Struct.new(:id, :libelle, :published_at, :aasm_state, :estimated_dossiers_count, :admin_count, :template, keyword_init: true) do
  include SpreadsheetArchitect

  def spreadsheet_columns
    [:id, :libelle, :published_at, :aasm_state, :admin_count, :template].map do |attribute|
      [I18n.t(attribute, scope: 'activerecord.attributes.procedure_export'), attribute]
    end
  end

  AdministrateursCounter = Struct.new(:count)

  def administrateurs
    AdministrateursCounter.new(admin_count)
  end
end
