module RecoverySelectionHelper
  def recoverable_id_and_libelles(recoverables)
    recoverables
      .map { |r| [r[:procedure_id], nice_libelle(r)] }
  end

  private

  def nice_libelle(recoverable)
    sanitize(
      "Nº #{number_with_html_delimiter(recoverable[:procedure_id])}" \
      " - #{recoverable[:libelle]} " \
      "#{tag.span(pluralize(recoverable[:count], 'dossier'), class: 'fr-tag fr-tag--sm')}"
    )
  end
end
