# frozen_string_literal: true

class ProcedureExportService
  attr_reader :procedure, :dossiers

  def initialize(procedure, dossiers, user_profile, export_template)
    @procedure = procedure
    @dossiers = dossiers
    @user_profile = user_profile
    @export_template = export_template
  end

  def to_csv
    @dossiers = @dossiers.downloadable_sorted_batch
    io = StringIO.new(SpreadsheetArchitect.to_csv(options_for(:dossiers, :csv)))
    create_blob(io, :csv)
  end

  def to_xlsx
    @dossiers = @dossiers.downloadable_sorted_batch
    tables = [:dossiers, :etablissements, :avis] + champs_repetables_options

    # We recursively build multi page spreadsheet
    io = tables.reduce(nil) do |package, table|
      SpreadsheetArchitect.to_axlsx_package(options_for(table, :xlsx), package)
    end.to_stream
    create_blob(io, :xlsx)
  end

  def to_ods
    @dossiers = @dossiers.downloadable_sorted_batch
    tables = [:dossiers, :etablissements, :avis] + champs_repetables_options

    # We recursively build multi page spreadsheet
    io = StringIO.new(tables.reduce(nil) do |spreadsheet, table|
      SpreadsheetArchitect.to_rodf_spreadsheet(options_for(table, :ods), spreadsheet)
    end.bytes)
    create_blob(io, :ods)
  end

  def to_zip
    attachments = ActiveStorage::DownloadableFile.create_list_from_dossiers(dossiers:, user_profile: @user_profile, export_template: @export_template)

    DownloadableFileService.download_and_zip(procedure, attachments, base_filename) do |zip_filepath|
      ArchiveUploader.new(procedure: procedure, filename: filename(:zip), filepath: zip_filepath).blob
    end
  end

  def to_geo_json
    io = StringIO.new(dossiers.to_feature_collection.to_json)
    create_blob(io, :json)
  end

  private

  def create_blob(io, format)
    ActiveStorage::Blob.create_and_upload!(
      io: io,
      filename: filename(format),
      content_type: content_type(format),
      identify: false,
      # We generate the exports ourselves, so they are safe
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE, identified: true }
    )
  end

  def base_filename
    @base_filename ||= "dossiers_#{procedure_identifier}_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M')}"
  end

  def filename(format)
    "#{base_filename}.#{format}"
  end

  def procedure_identifier
    procedure.path || "procedure-#{procedure.id}"
  end

  def content_type(format)
    case format
    when :csv
      'text/csv'
    when :xlsx
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    when :ods
      'application/vnd.oasis.opendocument.spreadsheet'
    when :zip
      'application/zip'
    when :json
      'application/json'
    end
  end

  def etablissements
    @etablissements ||= dossiers.flat_map do |dossier|
      dossier.champs.filter { _1.is_a?(Champs::SiretChamp) }
    end.filter_map(&:etablissement) + dossiers.filter_map(&:etablissement)
  end

  def avis
    @avis ||= dossiers.flat_map(&:avis)
  end

  def champs_repetables_options
    if @export_template.present?
      @export_template.repetable_columns.filter_map do |repetition, selected_children_columns|
        champs_by_stable_id = dossiers
          .flat_map { _1.champs.filter(&:repetition?) }
          .group_by(&:stable_id)

        rows = champs_by_stable_id.fetch(repetition.stable_id, []).flat_map(&:rows_for_export)

        if selected_children_columns.present? && rows.present?
          {
            sheet_name: repetition.libelle_for_export,
            instances: rows,
            spreadsheet_columns: Proc.new { |instance| instance.spreadsheet_columns(selected_children_columns) }
          }
        end
      end
    else
      champs_by_stable_id = dossiers
        .flat_map { _1.champs.filter(&:repetition?) }
        .group_by(&:stable_id)

      procedure
        .all_revisions_types_de_champ
        .repetition
        .filter_map do |type_de_champ_repetition|
          types_de_champ = procedure.all_revisions_types_de_champ(parent: type_de_champ_repetition).to_a
          rows = champs_by_stable_id.fetch(type_de_champ_repetition.stable_id, []).flat_map(&:rows_for_export)

          if types_de_champ.present? && rows.present?
            {
              sheet_name: type_de_champ_repetition.libelle_for_export,
              instances: rows,
              spreadsheet_columns: Proc.new { |instance| instance.spreadsheet_columns(types_de_champ) }
            }
          end
        end
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
    types_de_champ = procedure.types_de_champ_for_procedure_export.to_a

    Proc.new do |instance|
      instance.send(:"spreadsheet_columns_#{format}", types_de_champ: types_de_champ, export_template: @export_template)
    end
  end
end
