module Mutations
  class GroupeInstructeurCreer < Mutations::BaseMutation
    class GroupeInstructeurAttributes < Types::BaseInputObject
      description "Attributs pour l’ajout d'un groupe instructeur."
      argument :label, String, "Libelle du groupe instructeur.", required: true
      argument :closed, Boolean, "L’état du groupe instructeur.", required: false, default_value: false
      argument :instructeurs, [Types::ProfileInput], "Instructeurs à ajouter.", required: false, default_value: []
    end

    description "Crée un groupe instructeur."

    argument :demarche, Types::DemarcheDescriptorType::FindDemarcheInput, "Demarche ID ou numéro.", required: true
    argument :groupe_instructeur, GroupeInstructeurAttributes, "Groupes instructeur à ajouter.", required: true

    field :groupe_instructeur, Types::GroupeInstructeurType, null: true
    field :errors, [Types::ValidationErrorType], null: true
    field :warnings, [Types::WarningMessageType], null: true

    def resolve(demarche:, groupe_instructeur:)
      demarche_number = demarche.number.presence || ApplicationRecord.id_from_typed_id(demarche.id)
      procedure = current_administrateur.procedures.find(demarche_number)
      ids, emails = partition_instructeurs_by(groupe_instructeur.instructeurs)

      groupe_instructeur = procedure
        .groupe_instructeurs
        .build(label: groupe_instructeur.label, closed: groupe_instructeur.closed, instructeurs: [current_administrateur.instructeur].compact)

      if groupe_instructeur.save

        # ugly hack to keep retro compatibility
        # do not judge
        if !ENV['OLD_GROUPE_INSTRUCTEURS_CREATE_API_PROCEDURE_ID'].nil? && demarche_number.in?(ENV['OLD_GROUPE_INSTRUCTEURS_CREATE_API_PROCEDURE_ID']&.split(',')&.map(&:to_i))
          stable_id = procedure.groupe_instructeurs.first.routing_rule.left.stable_id
          tdc = procedure.published_revision.types_de_champ.find_by(stable_id: stable_ids)
          tdc.update(options: tdc.options['drop_down_options'].push(groupe_instructeur.label))
          groupe_instructeur.update(routing_rule: ds_eq(champ_value(stable_id), constant(groupe_instruteur.label)))
        end

        result = { groupe_instructeur: }

        if emails.present? || ids.present?
          _, invalid_emails = groupe_instructeur.add_instructeurs(ids:, emails:)

          groupe_instructeur.reload

          if invalid_emails.present?
            warning = I18n.t('administrateurs.groupe_instructeurs.add_instructeur.wrong_address',
              count: invalid_emails.size,
              emails: invalid_emails.join(', '))

            result[:warnings] = [warning]
          end
        end

        result
      else
        { errors: groupe_instructeur.errors.full_messages }
      end
    end
  end
end
