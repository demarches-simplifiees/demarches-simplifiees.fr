class FindDubiousProceduresJob < ApplicationJob
  queue_as :cron

  FORBIDDEN_KEYWORDS = ['IBAN', 'NIR', 'NIRPP', 'race', 'religion',
                        'carte bancaire', 'carte bleue', 'sécurité sociale']

  def perform(*args)
    # \\y is a word boundary
    forbidden_regexp = FORBIDDEN_KEYWORDS
      .map { |keyword| '\\y' + keyword + '\\y' }
      .join('|')

    # ~* -> case insensitive regexp match
    # https://www.postgresql.org/docs/current/static/functions-matching.html#FUNCTIONS-POSIX-REGEXP
    forbidden_tdcs = TypeDeChamp
      .joins(:procedure)
      .where("types_de_champ.libelle ~* '#{forbidden_regexp}'")
      .where(type_champ: %w(text textarea))
      .where(procedures: { archived_at: nil })

    dubious_procedures_and_tdcs = forbidden_tdcs
      .group_by(&:procedure_id)
      .map { |_procedure_id, tdcs| [tdcs[0].procedure, tdcs] }

    if dubious_procedures_and_tdcs.present?
      AdministrationMailer.dubious_procedures(dubious_procedures_and_tdcs).deliver_now
    end
  end
end
