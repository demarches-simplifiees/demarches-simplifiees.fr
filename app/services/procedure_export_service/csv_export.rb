# frozen_string_literal: true

# Streams a procedure's dossiers into a CSV file with bounded memory: rows are
# written batch by batch via DossierPreloader, so only one batch of dossiers
# (and their champs) is materialized at a time. Mirrors XlsxExport without its
# secondary sheets — the CSV is single-sheet, établissement columns inline.
class ProcedureExportService::CsvExport
  # Spreadsheets read a cell starting with one of these characters as a formula:
  # a leading apostrophe makes them display the text as typed. Plain numbers
  # ("-12", "+33 6 12 34 56 78") are kept as is.
  FORMULA_START = /\A[=+\-@\t\r]/
  PLAIN_NUMBER = /\A[+\-]?[\d\s.,]+\z/

  def self.as_text(value)
    if value.is_a?(String) && value.match?(FORMULA_START) && !value.match?(PLAIN_NUMBER)
      "'#{value}"
    else
      value
    end
  end

  def initialize(procedure:, dossiers:, export_template:)
    @procedure = procedure
    @dossiers = dossiers
    @export_template = export_template
  end

  def write_to(io)
    csv = CSV.new(io)
    headers_written = false

    DossierPreloader
      .new(@dossiers.ordered_for_export)
      .in_batches(includes: DossierPreloader::SHEET_EXPORT_INCLUDES) do |batch|
      batch.each do |dossier|
        columns = dossier.spreadsheet_columns_csv(type_de_champs:, export_template: @export_template)

        unless headers_written
          csv << columns.map { self.class.as_text(it.first) }
          headers_written = true
        end

        csv << columns.map { |(_libelle, value)| self.class.as_text(resolve(dossier, value)) }
      end
    end
  end

  private

  def resolve(instance, value)
    if value.is_a?(Symbol)
      instance.send(value)
    else
      value
    end
  end

  def type_de_champs = @type_de_champs ||= @procedure.type_de_champs_for_procedure_export.to_a
end
