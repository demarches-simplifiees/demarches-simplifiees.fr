class Dossier::RemoveTitreIdentiteJob < EventHandlerJob
  def perform(event)
    dossier
      .champs_public
      .filter(&:titre_identite?)
      .map(&:piece_justificative_file)
      .each(&:purge_later)
  end
end
