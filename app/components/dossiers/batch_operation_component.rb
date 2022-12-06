class Dossiers::BatchOperationComponent < ApplicationComponent
  attr_reader :statut, :procedure

  def initialize(statut:, procedure:)
    @statut = statut
    @procedure = procedure
  end

  def render?
    @statut == 'traites'
  end

  def available_operations
    options = []
    case @statut
    when 'traites' then
      options.push [t(".operations.archiver"), BatchOperation.operations.fetch(:archiver)]
    else
    end

    options
  end
end
