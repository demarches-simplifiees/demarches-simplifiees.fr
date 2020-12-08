class Cron::FindDubiousProceduresJob < Cron::CronJob
  self.schedule_expression = "every day at midnight"

  FORBIDDEN_KEYWORDS = [
    'NIR', 'NIRPP', 'race', 'religion',
    'carte bancaire', 'carte bleue', 'sécurité sociale',
    'agdref', 'syndicat', 'syndical',
    'parti politique', 'opinion politique', 'bord politique', 'courant politique',
    'médical', 'handicap', 'maladie', 'allergie', 'hospitalisé', 'RQTH', 'vaccin'
  ]

  def perform(*args)
    # \\y is a word boundary
    forbidden_regexp = FORBIDDEN_KEYWORDS
      .map { |keyword| "\\y#{keyword}\\y" }
      .join('|')

    # ~* -> case insensitive regexp match
    # https://www.postgresql.org/docs/current/static/functions-matching.html#FUNCTIONS-POSIX-REGEXP
    forbidden_tdcs = TypeDeChamp
      .joins(:procedure)
      .where("unaccent(types_de_champ.libelle) ~* unaccent(?)", forbidden_regexp)
      .where(type_champ: [TypeDeChamp.type_champs.fetch(:text), TypeDeChamp.type_champs.fetch(:textarea)])
      .where(procedures: { closed_at: nil, whitelisted_at: nil })

    dubious_procedures_and_tdcs = forbidden_tdcs
      .group_by { |type_de_champ| type_de_champ.procedure.id }
      .map { |_procedure_id, tdcs| [tdcs[0].procedure, tdcs] }

    AdministrationMailer.dubious_procedures(dubious_procedures_and_tdcs).deliver_later
  end
end
