# frozen_string_literal: true

class Dossiers::BatchOperationComponent < ApplicationComponent
  attr_reader :statut, :procedure

  def initialize(statut:, procedure:)
    @statut = statut
    @procedure = procedure
  end

  def render?
    ['a-suivre', 'traites', 'suivis', 'archives', 'supprimes', 'expirant'].include?(@statut)
  end

  def operations_for_dossier(dossier)
    case dossier.state
    when Dossier.states.fetch(:en_construction)
      [BatchOperation.operations.fetch(:passer_en_instruction), BatchOperation.operations.fetch(:repousser_expiration), BatchOperation.operations.fetch(:create_avis)]
    when Dossier.states.fetch(:en_instruction)
      [
        BatchOperation.operations.fetch(:accepter), BatchOperation.operations.fetch(:refuser),
        BatchOperation.operations.fetch(:classer_sans_suite), BatchOperation.operations.fetch(:repasser_en_construction), BatchOperation.operations.fetch(:create_avis)
      ]
    when Dossier.states.fetch(:accepte), Dossier.states.fetch(:refuse), Dossier.states.fetch(:sans_suite)
      [
        BatchOperation.operations.fetch(:archiver), BatchOperation.operations.fetch(:desarchiver), BatchOperation.operations.fetch(:supprimer),
        BatchOperation.operations.fetch(:restaurer), BatchOperation.operations.fetch(:repousser_expiration)
      ]
    else
      []
    end.append(BatchOperation.operations.fetch(:follow), BatchOperation.operations.fetch(:unfollow))
  end

  private

  def available_operations
    case @statut
    when 'a-suivre' then
      {
        options:
          [
            {
              label: t(".operations.passer_en_instruction"),
              operation: BatchOperation.operations.fetch(:passer_en_instruction)
            },
            {
              label: t(".operations.follow"),
              operation: BatchOperation.operations.fetch(:follow)
            }
          ]
      }
    when 'archives' then
      {
        options:
          [
            {
              label: t(".operations.desarchiver"),
              operation: BatchOperation.operations.fetch(:desarchiver)
            }
          ]
      }
    when 'traites' then
      {
        options:
          [
            {
              label: t(".operations.archiver"),
              operation: BatchOperation.operations.fetch(:archiver)
            },
            {
              label: t(".operations.supprimer"),
              operation: BatchOperation.operations.fetch(:supprimer)
            }
          ]
      }
    when 'expirant' then
      {
        options:
          [
            {
              label: t(".operations.repousser_expiration"),
              operation: BatchOperation.operations.fetch(:repousser_expiration)
            }
          ]
      }
    when 'supprimes' then
      {
        options:
          [
            {
              label: t(".operations.restaurer"),
              operation: BatchOperation.operations.fetch(:restaurer)
            }
          ]
      }
    when 'suivis' then
      {
        options:
          [

            {
              label: t(".operations.passer_en_instruction"),
              operation: BatchOperation.operations.fetch(:passer_en_instruction)
            },

            {
              instruction:
                            [
                              {
                                label: t(".operations.accepter"),
                                operation_description: t(".operations.accepter_description"),
                                operation: BatchOperation.operations.fetch(:accepter),
                                operation_class_name: 'fr-icon-checkbox-circle-fill fr-text-default--success',
                                placeholder: t(".placeholders.accepter"),
                                instruction_operation: 'accept'
                              },

                              {
                                label: t(".operations.classer_sans_suite"),
                                operation_description: t(".operations.classer_sans_suite_description"),
                                operation: BatchOperation.operations.fetch(:classer_sans_suite),
                                operation_class_name: 'fr-icon-intermediate-circle-fill fr-text-mention--grey',
                                placeholder: t(".placeholders.classer_sans_suite"),
                                instruction_operation: 'without-continuation'
                              },

                              {
                                label: t(".operations.refuser"),
                                operation_description: t(".operations.refuser_description"),
                                operation: BatchOperation.operations.fetch(:refuser),
                                operation_class_name: 'fr-icon-close-circle-fill fr-text-default--warning',
                                placeholder: t(".placeholders.refuser"),
                                instruction_operation: 'refuse'
                              }
                            ]
            },
            {
              label: t(".operations.unfollow"),
              operation: BatchOperation.operations.fetch(:unfollow)
            },

            {
              label: t(".operations.repasser_en_construction"),
              operation: BatchOperation.operations.fetch(:repasser_en_construction)
            },

            {
              label: t(".operations.create_avis"),
              operation: BatchOperation.operations.fetch(:create_avis),
              modal_data: { action: 'batch-operation#injectSelectedIdsIntoModal', 'fr-opened': "false" },
              aria:  'modal-avis-batch'

            }
          ]
      }
    else
      {
        options: []
      }
    end
  end

  def icons
    {
      accepter: 'fr-icon-success-line',
      archiver: 'fr-icon-folder-2-line',
      desarchiver: 'fr-icon-upload-2-line',
      follow: 'fr-icon-star-line',
      passer_en_instruction: 'fr-icon-edit-line',
      repasser_en_construction: 'fr-icon-draft-line',
      supprimer: 'fr-icon-delete-line',
      restaurer: 'fr-icon-refresh-line',
      unfollow: 'fr-icon-star-fill',
      create_avis: 'fr-icon-questionnaire-line'
    }
  end
end
