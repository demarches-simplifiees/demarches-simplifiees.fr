class DossierFieldService
  @@column_whitelist = {}

  class << self
    def fields(procedure)
      fields = [
        field_hash('Créé le', 'self', 'created_at'),
        field_hash('Mis à jour le', 'self', 'updated_at'),
        field_hash('Demandeur', 'user', 'email')
      ]

      fields.push(
        field_hash('Civilité (FC)', 'france_connect_information', 'gender'),
        field_hash('Prénom (FC)', 'france_connect_information', 'given_name'),
        field_hash('Nom (FC)', 'france_connect_information', 'family_name')
      )

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
      when 'france_connect_information'
        dossier.user.france_connect_information&.send(column)
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

    def filtered_ids(dossiers, filters)
      filters.map do |filter|
        table = filter['table']
        column = sanitized_column(filter)
        case table
        when 'self'
          dossiers.where("? ILIKE ?", filter['column'], "%#{filter['value']}%")

        when 'france_connect_information'
          dossiers
            .includes(user: :france_connect_information)
            .where("? ILIKE ?", "france_connect_informations.#{filter['column']}", "%#{filter['value']}%")

        when 'type_de_champ', 'type_de_champ_private'
          relation = table == 'type_de_champ' ? :champs : :champs_private
          dossiers
            .includes(relation)
            .where("champs.type_de_champ_id = ?", filter['column'].to_i)
            .where("champs.value ILIKE ?", "%#{filter['value']}%")
        when 'etablissement'
          if filter['column'] == 'entreprise_date_creation'
            date = filter['value'].to_date rescue nil
            dossiers
              .includes(table)
              .where("#{column} = ?", date)
          else
            dossiers
              .includes(table)
              .where("#{column} ILIKE ?", "%#{filter['value']}%")
          end
        when 'user'
          dossiers
            .includes(table)
            .where("#{column} ILIKE ?", "%#{filter['value']}%")
        end.pluck(:id)
      end.reduce(:&)
    end

    def sorted_ids(dossiers, procedure_presentation, gestionnaire)
      table = procedure_presentation.sort['table']
      column = sanitized_column(procedure_presentation.sort)
      order = procedure_presentation.sort['order']
      assert_valid_order(order)

      case table
      when 'notifications'
        procedure = procedure_presentation.assign_to.procedure
        dossiers_id_with_notification = gestionnaire.notifications_for_procedure(procedure)
        if order == 'desc'
          return dossiers_id_with_notification +
              (dossiers.order('dossiers.updated_at desc').ids - dossiers_id_with_notification)
        else
          return (dossiers.order('dossiers.updated_at asc').ids - dossiers_id_with_notification) +
              dossiers_id_with_notification
        end
      when 'self'
        return dossiers
            .order("#{column} #{order}")
            .pluck(:id)
      when 'france_connect_information'
        return dossiers
            .includes(user: :france_connect_information)
            .order("#{column} #{order}")
            .pluck(:id)
      when 'type_de_champ', 'type_de_champ_private'
        return dossiers
            .includes(table == 'type_de_champ' ? :champs : :champs_private)
            .where("champs.type_de_champ_id = #{procedure_presentation.sort['column'].to_i}")
            .order("champs.value #{order}")
            .pluck(:id)
      else
        return dossiers
            .includes(table)
            .order("#{column} #{order}")
            .pluck(:id)
      end
    end

    private

    def valid_columns_for_table(procedure, table)
      if !@@column_whitelist.key?(procedure.id)
        @@column_whitelist[procedure.id] = fields(procedure)
          .group_by { |field| field['table'] }
          .map { |table, fields| [table, Set.new(fields.map { |field| field['column'] }) ] }
          .to_h
      end

      @@column_whitelist[procedure.id][table] || []
    end

    def sanitized_column(field)
      table = field['table']
      table = ActiveRecord::Base.connection.quote_column_name((table == 'self' ? 'dossier' : table).pluralize)
      column = ActiveRecord::Base.connection.quote_column_name(field['column'])

      table + '.' + column
    end

    def assert_valid_order(order)
      if !["asc", "desc"].include?(order)
        raise "Invalid order #{order}"
      end
    end

    def field_hash(label, table, column)
      {
        'label' => label,
        'table' => table,
        'column' => column
      }
    end
  end
end
