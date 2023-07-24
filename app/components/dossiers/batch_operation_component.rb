class Dossiers::BatchOperationComponent < ApplicationComponent
  attr_reader :statut, :procedure

  def initialize(statut:, procedure:)
    @statut = statut
    @procedure = procedure
  end

  def render?
    ['a-suivre', 'traites', 'suivis'].include?(@statut)
  end

  def operations_for_dossier(dossier)
    case dossier.state
    when Dossier.states.fetch(:en_construction)
      [BatchOperation.operations.fetch(:passer_en_instruction)]
    when Dossier.states.fetch(:en_instruction)
      [BatchOperation.operations.fetch(:accepter), BatchOperation.operations.fetch(:refuser), BatchOperation.operations.fetch(:classer_sans_suite), BatchOperation.operations.fetch(:repasser_en_construction)]
    when Dossier.states.fetch(:accepte), Dossier.states.fetch(:refuse), Dossier.states.fetch(:sans_suite)
      [BatchOperation.operations.fetch(:archiver)]
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
              label: t(".operations.follow"),
              operation: BatchOperation.operations.fetch(:follow)
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
                                operation_class_name: 'accept',
                                placeholder: t(".placeholders.accepter")
                              },

                              {
                                label: t(".operations.refuser"),
                                operation_description: t(".operations.refuser_description"),
                                operation: BatchOperation.operations.fetch(:refuser),
                                operation_class_name: 'refuse',
                                placeholder: t(".placeholders.refuser")
                              },

                              {
                                label: t(".operations.classer_sans_suite"),
                                operation_description: t(".operations.classer_sans_suite_description"),
                                operation: BatchOperation.operations.fetch(:classer_sans_suite),
                                operation_class_name: 'without-continuation',
                                placeholder: t(".placeholders.classer_sans_suite")
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
      follow: 'fr-icon-star-line',
      passer_en_instruction: 'fr-icon-edit-line',
      repasser_en_construction: 'fr-icon-draft-line',
      unfollow: 'fr-icon-star-fill'
    }
  end
end
