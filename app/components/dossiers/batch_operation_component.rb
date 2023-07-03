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
      [BatchOperation.operations.fetch(:accepter)]
    when Dossier.states.fetch(:accepte), Dossier.states.fetch(:refuse), Dossier.states.fetch(:sans_suite)
      [BatchOperation.operations.fetch(:archiver)]
    else
      []
    end
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
              label: t(".operations.accepter"),
              operation: BatchOperation.operations.fetch(:accepter)
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
      passer_en_instruction: 'fr-icon-edit-line'
    }
  end
end
