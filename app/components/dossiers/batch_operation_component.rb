class Dossiers::BatchOperationComponent < ApplicationComponent
  attr_reader :statut, :procedure

  def initialize(statut:, procedure:)
    @statut = statut
    @procedure = procedure
  end

  def render?
    ['traites', 'suivis'].include?(@statut)
  end

  def available_operations
    case @statut
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
      archiver: 'fr-icon-folder-2-line',
      passer_en_instruction: 'fr-icon-edit-line',
      accepter: 'fr-icon-success-line'
    }
  end
end
