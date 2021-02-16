# rubocop:disable DS/ApplicationName
# API URLs
API_CARTO_URL = ENV.fetch("API_CARTO_URL", "https://sandbox.geo.api.gouv.fr/apicarto")
API_ENTREPRISE_URL = ENV.fetch("API_ENTREPRISE_URL", "https://entreprise.api.gouv.fr/v2")
API_EDUCATION_URL = ENV.fetch("API_EDUCATION_URL", "https://data.education.gouv.fr/api/records/1.0")
HELPSCOUT_API_URL = ENV.fetch("HELPSCOUT_API_URL", "https://api.helpscout.net/v2")
PIPEDRIVE_API_URL = ENV.fetch("PIPEDRIVE_API_URL", "https://api.pipedrive.com/v1")
SENDINBLUE_API_URL = ENV.fetch("SENDINBLUE_API_URL", "https://in-automate.sendinblue.com/api/v2")
SENDINBLUE_API_V3_URL = ENV.fetch("SENDINBLUE_API_V3_URL", "https://api.sendinblue.com/v3")
UNIVERSIGN_API_URL = ENV.fetch("UNIVERSIGN_API_URL", "https://ws.universign.eu/tsa/post/")
FEATURE_UPVOTE_URL = ENV.fetch("FEATURE_UPVOTE_URL", "https://demarches-simplifiees.featureupvote.com")

# Internal URLs
FOG_BASE_URL = "https://static.#{FR_SITE}"

# External services URLs
WEBINAIRE_URL = "https://app.livestorm.co/demarches-simplifiees"
CALENDLY_URL = "https://calendly.com/demarches-simplifiees/accompagnement-administrateur-demarches-simplifiees-fr"

FR_DOC_URL = "https://doc.#{FR_SITE}"
DOC_URL = ENV.fetch("DOC_URL", "https://mes-demarches.gitbook.io/documentation")
DOC_NOUVEAUTES_URL = [DOC_URL, "nouveautes"].join("/")
ADMINISTRATEUR_TUTORIAL_URL = [DOC_URL, "dematerialiser-un-formulaire-1", "tutoriels", "dematerialiser-formulaire"].join("/")
INSTRUCTEUR_TUTORIAL_URL = [DOC_URL, "dematerialiser-un-formulaire-1", "tutoriels"].join("/")
CADRE_JURIDIQUE_URL = [ADMINISTRATEUR_TUTORIAL_URL, "cadre-juridique"].join("#") # TODO version polynésie
LISTE_DES_DEMARCHES_URL = "https://www.service-public.pf/demarches-simplifiees"
CGU_URL = ENV.fetch("CGU_URL", [DOC_URL, "cgu"].join("/"))
RGPD_URL = [CGU_URL, "rgpd"].join("#")
MENTIONS_LEGALES_URL = ENV.fetch("MENTIONS_LEGALES_URL", [CGU_URL, "mentions-legales"].join("#"))
API_DOC_URL = [FR_DOC_URL, "pour-aller-plus-loin", "api"].join("/")
WEBHOOK_DOC_URL = [FR_DOC_URL, "pour-aller-plus-loin", "webhook"].join("/")
ARCHIVAGE_DOC_URL = [FR_DOC_URL, "pour-aller-plus-loin", "archivage-longue-duree-des-demarches"].join("/")
DOC_INTEGRATION_MONAVIS_URL = [FR_DOC_URL, "tutoriels", "integration-du-bouton-mon-avis"].join("/")

FAQ_URL = [DOC_URL, "questions-frequentes"].join("/")
FR_FAQ_URL = "https://faq.demarches-simplifiees.fr"
FAQ_ADMIN_URL = [FR_FAQ_URL, "collection", "1-administrateur-creation-dun-formulaire"].join("/")
FAQ_AUTOSAVE_URL = [FR_FAQ_URL, "article", "77-enregistrer-mon-formulaire-pour-le-reprendre-plus-tard?preview=5ec28ca1042863474d1aee00"].join("/")
COMMENT_TROUVER_MA_DEMARCHE_URL = [FR_FAQ_URL, "article", "59-comment-trouver-ma-demarche"].join("/")
FAQ_CONFIRMER_COMPTE_CHAQUE_CONNEXION_URL = [FR_FAQ_URL, "article", "34-je-dois-confirmer-mon-compte-a-chaque-connexion"].join("/")
FAQ_EMAIL_NON_RECU_URL = [FR_FAQ_URL, "article", "79-je-ne-recois-pas-demail"].join("/")
FAQ_CONTACTER_SERVICE_EN_CHARGE_URL = [FR_FAQ_URL, "article", "12-contacter-le-service-en-charge-de-ma-demarche"].join("/")
FAQ_OU_EN_EST_MON_DOSSIER_URL = [FR_FAQ_URL, "article", "11-je-veux-savoir-ou-en-est-linstruction-de-ma-demarche"].join("/")
FAQ_ERREUR_SIRET_URL = "https://doc.projet.gov.pf/pages/viewpage.action?pageId=19764340"

STATUS_PAGE_URL = ENV.fetch("STATUS_PAGE_URL", "https://updown.io/cugq")
DEMANDE_INSCRIPTION_ADMIN_PAGE_URL = ENV.fetch("DEMANDE_INSCRIPTION_ADMIN_PAGE_URL", "https://www.demarches-simplifiees.fr/commencer/demande-d-inscription-a-demarches-simplifiees")
MATOMO_IFRAME_URL = 'https://beta.mes-demarches.gov.pf/matomo/index.php?module=CoreAdminHome&action=optOut&language=fr&backgroundColor=ffffff&fontColor=333333&fontSize=16px&fontFamily=Muli'

#----- Polynesian variables

API_TE_FENUA_URL = ENV.fetch("API_TE_FENUA_URL", "https://www.tefenua.gov.pf/api")

API_ENTREPRISE_PF_AUTH = ENV.fetch("API_ENTREPRISE_PF_AUTH", "https://auth.gov.pf/auth/realms/Itaiete/protocol/openid-connect/token")
API_ENTREPRISE_PF_URL = ENV.fetch("API_ENTREPRISE_PF_URL", "https://www.i-taiete.gov.pf/api/v2")

API_CPS_AUTH = ENV.fetch("API_CPS_AUTH", "https://connect.cps.pf/auth/realms/TatouAssures/protocol/openid-connect/token")
API_CPS_URL = ENV.fetch("API_CPS_URL", "https://tatouapi.cps.pf")

# rubocop:enable DS/ApplicationName
