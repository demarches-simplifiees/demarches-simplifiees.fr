class ProcedureExportService
  attr_reader :dossiers

  def initialize(procedure, dossiers)
    @procedure = procedure
    @dossiers = dossiers.downloadable_sorted
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
    end.map(&:etablissement).compact + dossiers.map(&:etablissement).compact
  end

  def avis
    @avis ||= dossiers.flat_map(&:avis)
  end

  def champs_repetables
    @champs_repetables ||= dossiers.flat_map do |dossier|
      [dossier.champs, dossier.champs_private]
        .flatten
        .filter { |champ| champ.is_a?(Champs::RepetitionChamp) }
    end.group_by(&:libelle_for_export)
  end

  def champs_repetables_options
    champs_repetables.map do |libelle, champs|
      [
        libelle,
        champs.flat_map(&:rows_for_export)
      ]
    end
  end

  DEFAULT_STYLES = {
    header_style: { background_color: "700000", color: "FFFFFF", font_size: 12, bold: true },
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
    when Array
      { instances: table.last, sheet_name: table.first }
    end.merge(DEFAULT_STYLES).merge(@procedure.column_styles(table))

    # transliterate: convert to ASCII characters
    # to ensure truncate respects 30 bytes
    # /\*?[] are invalid Excel worksheet characters
    options[:sheet_name] = I18n.transliterate(options[:sheet_name], replacement: '', locale: :en)
      .delete('/\*?[]')
      .truncate(30, omission: '')

    options
  end

  def spreadsheet_columns(format)
    types_de_champ = @procedure.types_de_champ_for_export
    types_de_champ_private = @procedure.types_de_champ_private_for_export

    Proc.new do |instance|
      instance.send(:"spreadsheet_columns_#{format}", types_de_champ: types_de_champ, types_de_champ_private: types_de_champ_private)
    end
  end
end
