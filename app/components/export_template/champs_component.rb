class ExportTemplate::ChampsComponent < ApplicationComponent
  attr_reader :sections, :export_template, :title

  def initialize(title, export_template, types_de_champ)
    @title = title
    @export_template = export_template
    @types_de_champ = types_de_champ
    @sections ||= to_sections
  end

  def historical_libelle(column)
    historical_exported_column = export_template.exported_columns.find { _1.column == column }
    if historical_exported_column
      historical_exported_column.libelle
    else
      column.label
    end
  end

  private

  def to_sections
    sections = []
    current_section = { columns: [] }
    @types_de_champ.each do |current_tdc|
      if current_tdc.header_section?
        sections.push(current_section) if current_section[:columns].any?
        current_section = { libelle: current_tdc.libelle, columns: [] }
      else
        current_section[:columns].push(tdc_to_columns(current_tdc))
      end
    end
    sections.push(current_section) if current_section[:columns].any?
    sections
  end

  def tdc_to_columns(type_de_champ)
    prefix = type_de_champ.repetition? ? "Bloc répétable" : nil
    type_de_champ.columns(procedure_id: export_template.procedure.id, prefix:)
  end
end
