class DossierFieldService
  def initialize
    @column_whitelist = {}
  end

  def fields(procedure)
    fields = [
      field_hash('Créé le', 'self', 'created_at'),
      field_hash('Mis à jour le', 'self', 'updated_at'),
      field_hash('Demandeur', 'user', 'email')
    ]

    if !procedure.for_individual || (procedure.for_individual && procedure.individual_with_siret)
      fields.push(
        field_hash('SIREN', 'etablissement', 'entreprise_siren'),
        field_hash('Forme juridique', 'etablissement', 'entreprise_forme_juridique'),
        field_hash('Nom commercial', 'etablissement', 'entreprise_nom_commercial'),
        field_hash('Raison sociale', 'etablissement', 'entreprise_raison_sociale'),
        field_hash('SIRET siège social', 'etablissement', 'entreprise_siret_siege_social'),
        field_hash('Date de création', 'etablissement', 'entreprise_date_creation')
      )

      fields.push(
        field_hash('SIRET', 'etablissement', 'siret'),
        field_hash('Libellé NAF', 'etablissement', 'libelle_naf'),
        field_hash('Code postal', 'etablissement', 'code_postal')
      )
    end

    explanatory_types_de_champ = [:header_section, :explication].map{ |k| TypeDeChamp.type_champs.fetch(k) }

    fields.concat procedure.types_de_champ
      .reject { |tdc| explanatory_types_de_champ.include?(tdc.type_champ) }
      .map { |type_de_champ| field_hash(type_de_champ.libelle, 'type_de_champ', type_de_champ.id.to_s) }

    fields.concat procedure.types_de_champ_private
      .reject { |tdc| explanatory_types_de_champ.include?(tdc.type_champ) }
      .map { |type_de_champ| field_hash(type_de_champ.libelle, 'type_de_champ_private', type_de_champ.id.to_s) }

    fields
  end

  def get_value(dossier, table, column)
    assert_valid_column(dossier.procedure, table, column)

    case table
    when 'self'
      dossier.send(column)
    when 'user'
      dossier.user.send(column)
    when 'etablissement'
      dossier.etablissement&.send(column)
    when 'type_de_champ'
      dossier.champs.find { |c| c.type_de_champ_id == column.to_i }.value
    when 'type_de_champ_private'
      dossier.champs_private.find { |c| c.type_de_champ_id == column.to_i }.value
    end
  end

  def assert_valid_column(procedure, table, column)
    if !valid_column?(procedure, table, column)
      raise "Invalid column #{table}.#{column}"
    end
  end

  def valid_column?(procedure, table, column)
    valid_columns_for_table(procedure, table).include?(column)
  end

  private

  def valid_columns_for_table(procedure, table)
    if !@column_whitelist.key?(procedure.id)
      @column_whitelist[procedure.id] = fields(procedure)
        .group_by { |field| field['table'] }
        .map { |table, fields| [table, Set.new(fields.map { |field| field['column'] }) ] }
        .to_h
    end

    @column_whitelist[procedure.id][table] || []
  end

  def field_hash(label, table, column)
    {
      'label' => label,
      'table' => table,
      'column' => column
    }
  end
end
