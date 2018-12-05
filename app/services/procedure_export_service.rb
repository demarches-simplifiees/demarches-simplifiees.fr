class ProcedureExportService
  include DossierHelper

  ATTRIBUTES = [
    :id,
    :created_at,
    :updated_at,
    :archived,
    :email,
    :state,
    :initiated_at,
    :received_at,
    :processed_at,
    :motivation,
    :emails_instructeurs,
    :individual_gender,
    :individual_prenom,
    :individual_nom,
    :individual_birthdate
  ]

  ETABLISSEMENT_ATTRIBUTES = [
    :siret,
    :siege_social,
    :naf,
    :libelle_naf,
    :adresse,
    :numero_voie,
    :type_voie,
    :nom_voie,
    :complement_adresse,
    :code_postal,
    :localite,
    :code_insee_localite
  ]

  ENTREPRISE_ATTRIBUTES = [
    :siren,
    :capital_social,
    :numero_tva_intracommunautaire,
    :forme_juridique,
    :forme_juridique_code,
    :nom_commercial,
    :raison_sociale,
    :siret_siege_social,
    :code_effectif_entreprise,
    :date_creation,
    :nom,
    :prenom
  ]

  def initialize(procedure, tables: [], ids: nil, since: nil, limit: nil)
    @procedure = procedure
    @dossiers = procedure.dossiers.downloadable_sorted
    if ids
      @dossiers = @dossiers.where(id: ids)
    end
    if since
      @dossiers = @dossiers.since(since)
    end
    if limit
      @dossiers = @dossiers.limit(limit)
    end
    @dossiers = @dossiers.to_a
    @tables = tables.map(&:to_sym)
  end

  def to_csv
    SpreadsheetArchitect.to_csv(to_data(:dossiers))
  end

  def to_xlsx
    package = SpreadsheetArchitect.to_axlsx_package(to_data(:dossiers))

    # Next we recursively build multi page spreadsheet
    @tables.reduce(package) do |package, table|
      SpreadsheetArchitect.to_axlsx_package(to_data(table), package)
    end.to_stream.read
  end

  def to_ods
    spreadsheet = SpreadsheetArchitect.to_rodf_spreadsheet(to_data(:dossiers))

    # Next we recursively build multi page spreadsheet
    @tables.reduce(spreadsheet) do |spreadsheet, table|
      SpreadsheetArchitect.to_rodf_spreadsheet(to_data(table), spreadsheet)
    end.bytes
  end

  def to_data(table)
    case table
    when :dossiers
      dossiers_table_data
    when :etablissements
      etablissements_table_data
    end
  end

  private

  def empty_table_data(sheet_name, headers = [])
    {
      sheet_name: sheet_name,
      headers: headers,
      data: [[]]
    }
  end

  def dossiers_table_data
    if @dossiers.any?
      {
        sheet_name: 'Dossiers',
        headers: dossiers_headers,
        data: dossiers_data
      }
    else
      empty_table_data('Dossiers', dossiers_headers)
    end
  end

  def etablissements_table_data
    @etablissements = @dossiers.flat_map do |dossier|
      dossier.champs.select do |champ|
        champ.is_a?(Champs::SiretChamp)
      end + dossier.champs_private.select do |champ|
        champ.is_a?(Champs::SiretChamp)
      end
    end.map(&:etablissement).compact

    if @etablissements.any?
      {
        sheet_name: 'Etablissements',
        headers: etablissements_headers,
        data: etablissements_data
      }
    else
      empty_table_data('Etablissements', etablissements_headers)
    end
  end

  def dossiers_headers
    headers = ATTRIBUTES.map do |key|
      label_for_export(key.to_s)
    end
    headers += @procedure.types_de_champ.map do |champ|
      label_for_export(champ.libelle)
    end
    headers += @procedure.types_de_champ_private.map do |champ|
      label_for_export(champ.libelle)
    end
    headers += ETABLISSEMENT_ATTRIBUTES.map do |key|
      label_for_export("etablissement.#{key}")
    end
    headers += ENTREPRISE_ATTRIBUTES.map do |key|
      label_for_export("entreprise.#{key}")
    end
    headers
  end

  def dossiers_data
    @dossiers.map do |dossier|
      values = ATTRIBUTES.map do |key|
        case key
        when :email
          dossier.user.email
        when :state
          dossier_legacy_state(dossier)
        when :initiated_at
          dossier.en_construction_at
        when :received_at
          dossier.en_instruction_at
        when :individual_prenom
          dossier.individual&.prenom
        when :individual_nom
          dossier.individual&.nom
        when :individual_birthdate
          dossier.individual&.birthdate
        when :individual_gender
          dossier.individual&.gender
        when :emails_instructeurs
          dossier.followers_gestionnaires.map(&:email).join(' ')
        else
          dossier.read_attribute(key)
        end
      end
      values = normalize_values(values)
      values += dossier.champs.map do |champ|
        value_for_export(champ)
      end
      values += dossier.champs_private.map do |champ|
        value_for_export(champ)
      end
      values += etablissement_data(dossier.etablissement)
      values
    end
  end

  def etablissements_headers
    headers = [:dossier_id, :libelle]
    headers += ETABLISSEMENT_ATTRIBUTES.map do |key|
      label_for_export("etablissement.#{key}")
    end
    headers += ENTREPRISE_ATTRIBUTES.map do |key|
      label_for_export("entreprise.#{key}")
    end
    headers
  end

  def etablissements_data
    @etablissements.map do |etablissement|
      data = [
        etablissement.champ.dossier_id,
        label_for_export(etablissement.champ.libelle).to_s
      ]
      data += etablissement_data(etablissement)
    end
  end

  def etablissement_data(etablissement)
    data = ETABLISSEMENT_ATTRIBUTES.map do |key|
      if etablissement.present?
        case key
        when :adresse
          etablissement.adresse&.chomp&.gsub("\r\n", ' ')&.delete("\r")
        else
          etablissement.read_attribute(key)
        end
      end
    end
    data += ENTREPRISE_ATTRIBUTES.map do |key|
      if etablissement.present?
        case key
        when :date_creation
          etablissement.entreprise_date_creation&.to_datetime
        else
          etablissement.read_attribute(:"entreprise_#{key}")
        end
      end
    end
    normalize_values(data)
  end

  def label_for_export(label)
    label.parameterize.underscore.to_sym
  end

  def value_for_export(champ)
    champ.for_export
  end

  def normalize_values(values)
    values.map do |value|
      case value
      when TrueClass, FalseClass
        value.to_s
      else
        value.blank? ? nil : value.to_s
      end
    end
  end
end
