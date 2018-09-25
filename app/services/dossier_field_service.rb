class DossierFieldService
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

    def filtered_ids(dossiers, filters)
      filters.map do |filter|
        case filter['table']
        when 'self'
          dossiers.where("? ILIKE ?", filter['column'], "%#{filter['value']}%")

        when 'france_connect_information'
          dossiers
            .includes(user: :france_connect_information)
            .where("? ILIKE ?", "france_connect_informations.#{filter['column']}", "%#{filter['value']}%")

        when 'type_de_champ', 'type_de_champ_private'
          relation = filter['table'] == 'type_de_champ' ? :champs : :champs_private
          dossiers
            .includes(relation)
            .where("champs.type_de_champ_id = ?", filter['column'].to_i)
            .where("champs.value ILIKE ?", "%#{filter['value']}%")
        when 'etablissement'
          table = filter['table']
          if filter['column'] == 'entreprise_date_creation'
            date = filter['value'].to_date rescue nil
            dossiers
              .includes(table)
              .where("#{table.pluralize}.#{filter['column']} = ?", date)
          else
            dossiers
              .includes(table)
              .where("#{table.pluralize}.#{filter['column']} ILIKE ?", "%#{filter['value']}%")
          end
        when 'user'
          dossiers
            .includes(filter['table'])
            .where("#{filter['table'].pluralize}.#{filter['column']} ILIKE ?", "%#{filter['value']}%")
        end.pluck(:id)
      end.reduce(:&)
    end

    def sorted_ids(dossiers, procedure_presentation, gestionnaire)
      table = procedure_presentation.sort['table']
      column = procedure_presentation.sort['column']
      order = procedure_presentation.sort['order']
      includes = ''
      where = ''

      sorted_ids = nil

      case table
      when 'notifications'
        procedure = procedure_presentation.assign_to.procedure
        dossiers_id_with_notification = gestionnaire.notifications_for_procedure(procedure)
        if order == 'desc'
          sorted_ids = dossiers_id_with_notification + (dossiers.order('dossiers.updated_at desc').ids - dossiers_id_with_notification)
        else
          sorted_ids = (dossiers.order('dossiers.updated_at asc').ids - dossiers_id_with_notification) + dossiers_id_with_notification
        end
      when 'self'
        order = "dossiers.#{column} #{order}"
      when 'france_connect_information'
        includes = { user: :france_connect_information }
        order = "france_connect_informations.#{column} #{order}"
      when 'type_de_champ', 'type_de_champ_private'
        includes = table == 'type_de_champ' ? :champs : :champs_private
        where = "champs.type_de_champ_id = #{column.to_i}"
        order = "champs.value #{order}"
      else
        includes = table
        order = "#{table.pluralize}.#{column} #{order}"
      end

      if sorted_ids.nil?
        sorted_ids = dossiers.includes(includes).where(where).order(Dossier.sanitize_for_order(order)).pluck(:id)
      end

      sorted_ids
    end

    private

    def field_hash(label, table, column)
      {
        'label' => label,
        'table' => table,
        'column' => column
      }
    end
  end
end
