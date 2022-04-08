class ProcedureExportService
  attr_reader :procedure, :dossiers

  def initialize(procedure, dossiers)
    @procedure = procedure
    @dossiers = dossiers.downloadable_sorted_batch
    @tables = [:dossiers, :etablissements, :avis] + champs_repetables_options
  end

  def to_csv
    SpreadsheetArchitect.to_csv(options_for(:dossiers, :csv))
  end

  def to_xlsx
    # We recursively build multi page spreadsheet
    @tables.reduce(nil) do |package, table|
      SpreadsheetArchitect.to_axlsx_package(options_for(table, :xlsx), package)
    end.to_stream.read
  end

  def to_ods
    # We recursively build multi page spreadsheet
    @tables.reduce(nil) do |spreadsheet, table|
      SpreadsheetArchitect.to_rodf_spreadsheet(options_for(table, :ods), spreadsheet)
    end.bytes
  end

  private

  def etablissements
    @etablissements ||= dossiers.flat_map do |dossier|
      [dossier.champs, dossier.champs_private]
        .flatten
        .filter { |champ| champ.is_a?(Champs::SiretChamp) }
    end.filter_map(&:etablissement) + dossiers.filter_map(&:etablissement)
  end

  def avis
    @avis ||= dossiers.flat_map(&:avis)
  end

  def champs_repetables_options
    revision = procedure.active_revision
    champs_by_stable_id = dossiers
      .flat_map { |dossier| (dossier.champs + dossier.champs_private).filter(&:repetition?) }
      .group_by(&:stable_id)

    procedure.types_de_champ_for_procedure_presentation.repetition
      .map { |type_de_champ_repetition| [type_de_champ_repetition, type_de_champ_repetition.types_de_champ_for_revision(revision).to_a] }
      .filter { |(_, types_de_champ)| types_de_champ.present? }
      .map do |(type_de_champ_repetition, types_de_champ)|
        {
          sheet_name: type_de_champ_repetition.libelle_for_export,
          instances: champs_by_stable_id.fetch(type_de_champ_repetition.stable_id, []).flat_map(&:rows_for_export),
          spreadsheet_columns: Proc.new { |instance| instance.spreadsheet_columns(types_de_champ) }
        }
      end
  end

  DEFAULT_STYLES = {
    header_style: { background_color: "000000", color: "FFFFFF", font_size: 12, bold: true },
    row_style: { background_color: nil, color: "000000", font_size: 12 }
  }

  def options_for(table, format)
    options = case table
    when :dossiers
      { instances: dossiers.to_a, sheet_name: 'Dossiers', spreadsheet_columns: spreadsheet_columns(format) }
    when :etablissements
      { instances: etablissements.to_a, sheet_name: 'Etablissements' }
    when :avis
      { instances: avis.to_a, sheet_name: 'Avis' }
    when Hash
      table
    end.merge(DEFAULT_STYLES)

    # transliterate: convert to ASCII characters
    # to ensure truncate respects 30 bytes
    # /\*?[] are invalid Excel worksheet characters
    options[:sheet_name] = I18n.transliterate(options[:sheet_name], locale: :en)
      .delete('/\*?[]')
      .truncate(30, omission: '')

    options
  end

  def spreadsheet_columns(format)
    types_de_champ = procedure.types_de_champ_for_procedure_presentation.not_repetition.to_a

    Proc.new do |instance|
      instance.send(:"spreadsheet_columns_#{format}", types_de_champ: types_de_champ)
    end
  end
end
