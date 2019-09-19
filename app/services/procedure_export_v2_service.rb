class ProcedureExportV2Service
  attr_reader :dossiers

  def initialize(procedure, dossiers, ids: nil, since: nil, limit: nil)
    @procedure = procedure
    @dossiers = dossiers.downloadable_sorted
    if ids
      @dossiers = @dossiers.where(id: ids)
    end
    if since
      @dossiers = @dossiers.since(since)
    end
    if limit
      @dossiers = @dossiers.limit(limit)
    end
    @tables = [:dossiers, :etablissements, :avis] + champs_repetables_options
  end

  def to_csv(table = :dossiers)
    SpreadsheetArchitect.to_csv(options_for(table))
  end

  def to_xlsx
    # We recursively build multi page spreadsheet
    @tables.reduce(nil) do |package, table|
      SpreadsheetArchitect.to_axlsx_package(options_for(table), package)
    end.to_stream.read
  end

  def to_ods
    # We recursively build multi page spreadsheet
    @tables.reduce(nil) do |spreadsheet, table|
      SpreadsheetArchitect.to_rodf_spreadsheet(options_for(table), spreadsheet)
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
    end.group_by(&:libelle)
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
    header_style: { background_color: "000000", color: "FFFFFF", font_size: 12, bold: true },
    row_style: { background_color: nil, color: "000000", font_size: 12 }
  }

  def sanitize_sheet_name(name)
    ActiveStorage::Filename.new(name.to_s).sanitized.truncate(30)
  end

  def options_for(table)
    case table
    when :dossiers
      { instances: dossiers.to_a, sheet_name: 'Dossiers' }.merge(DEFAULT_STYLES)
    when :etablissements
      { instances: etablissements.to_a, sheet_name: 'Etablissements' }.merge(DEFAULT_STYLES)
    when :avis
      { instances: avis.to_a, sheet_name: 'Avis' }.merge(DEFAULT_STYLES)
    when Array
      # We have to truncate the label here as spreadsheets have a (30 char) limit on length.
      { instances: table.last, sheet_name: sanitize_sheet_name(table.first) }.merge(DEFAULT_STYLES)
    end
  end
end
