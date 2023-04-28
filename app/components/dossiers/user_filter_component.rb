class Dossiers::UserFilterComponent < ApplicationComponent
  def initialize(statut:, filter:)
    @statut = statut
    @filter = filter
  end

  attr_reader :statut, :filter

  def render?
    ['en-cours', 'traites'].include?(@statut)
  end

  def states_collection(statut)
    case statut
    when 'en-cours'
      Dossier.states.values - Dossier::TERMINE
    when 'traites'
      Dossier::TERMINE
    end
  end
end
