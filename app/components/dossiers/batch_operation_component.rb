class Dossiers::BatchOperationComponent < ApplicationComponent
  attr_reader :statut, :procedure

  def initialize(statut:, procedure:)
    @statut = statut
    @procedure = procedure
  end

  def render?
    ['a-suivre', 'traites', 'suivis'].include?(@statut)
  end

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
