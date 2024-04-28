# frozen_string_literal: true

module PapertrailHelper
  def papertrail_requester_identity(dossier)
    if dossier.etablissement.present?
      raison_sociale_or_name(dossier.etablissement)
    else
      [dossier.individual.prenom, dossier.individual.nom.upcase].join(' ')
    end
  end

  def papertrail_dossier_state(dossier)
    raise "Dossiers in 'brouillon' state are not supported" if dossier.brouillon?
    # i18n-tasks-use t('users.dossiers.papertrail.dossier_state.en_construction')
    # i18n-tasks-use t('users.dossiers.papertrail.dossier_state.en_instruction')
    # i18n-tasks-use t('users.dossiers.papertrail.dossier_state.accepte')
    # i18n-tasks-use t('users.dossiers.papertrail.dossier_state.refuse')
    # i18n-tasks-use t('users.dossiers.papertrail.dossier_state.sans_suite')
    I18n.t("users.dossiers.papertrail.states.#{dossier.state}")
  end
end
