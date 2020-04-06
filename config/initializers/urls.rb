# API URLs
API_CARTO_URL = ENV.fetch("API_CARTO_URL", "https://sandbox.geo.api.gouv.fr/apicarto")
API_ENTREPRISE_URL = ENV.fetch("API_ENTREPRISE_URL", "https://entreprise.api.gouv.fr/v2")
API_TE_FENUA_URL = ENV.fetch("API_TE_FENUA_URL", "https://www.tefenua.gov.pf/api")
HELPSCOUT_API_URL = ENV.fetch("HELPSCOUT_API_URL", "https://api.helpscout.net/v2")
PIPEDRIVE_API_URL = ENV.fetch("PIPEDRIVE_API_URL", "https://api.pipedrive.com/v1")
SENDINBLUE_API_URL = ENV.fetch("SENDINBLUE_API_URL", "https://in-automate.sendinblue.com/api/v2")
SENDINBLUE_API_V3_URL = ENV.fetch("SENDINBLUE_API_V3_URL", "https://api.sendinblue.com/v3")
UNIVERSIGN_API_URL = ENV.fetch("UNIVERSIGN_API_URL", "https://ws.universign.eu/tsa/post/")

API_ENTREPRISE_PF_AUTH = ENV.fetch("API_ENTREPRISE_PF_AUTH", "https://auth.gov.pf/auth/realms/Itaiete/protocol/openid-connect/token")
API_ENTREPRISE_PF_URL = ENV.fetch("API_ENTREPRISE_PF_URL", "https://ppr.api.i-taiete2.gov.pf/api/v2")

# Internal URLs
FOG_BASE_URL = "https://static.#{FR_SITE}"

# External services URLs
FR_DOC_URL = "https://doc.#{FR_SITE}"
DOC_URL = "https://mes-demarches.gitbook.io/documentation"
ADMINISTRATEUR_TUTORIAL_URL = [DOC_URL, "dematerialiser-un-formulaire-1", "tutoriels", "dematerialiser-formulaire"].join("/")
INSTRUCTEUR_TUTORIAL_URL = [DOC_URL, "dematerialiser-un-formulaire-1", "tutoriels"].join("/")
CADRE_JURIDIQUE_URL = [ADMINISTRATEUR_TUTORIAL_URL, "cadre-juridique"].join("#") # TODO version polynésie
WEBINAIRE_URL = "https://app.livestorm.co/demarches-simplifiees"
LISTE_DES_DEMARCHES_URL = "https://www.service-public.pf/demarches-simplifiees"

CGU_URL = [DOC_URL, "cgu"].join("/")
RGPD_URL = [CGU_URL, "rgpd"].join("#")
MENTIONS_LEGALES_URL = [CGU_URL, "mentions-legales"].join("#")

API_DOC_URL = [FR_DOC_URL, "pour-aller-plus-loin", "api"].join("/")
WEBHOOK_DOC_URL = [FR_DOC_URL, "pour-aller-plus-loin", "webhook"].join("/")

FAQ_URL = [DOC_URL, "questions-frequentes"].join("/")
FR_FAQ_URL = "https://faq.#{FR_SITE}"
FR_FAQ_ADMIN_URL = "#{FR_FAQ_URL}/collection/1-administrateur"
FAQ_ADMIN_URL = FR_FAQ_ADMIN_URL

COMMENT_TROUVER_MA_DEMARCHE_URL = [FAQ_URL, 'general', 'comment-trouver-ma-demarche'].join("/")

STATUS_PAGE_URL = "https://updown.io/cugq"
MATOMO_IFRAME_URL = 'https://beta.mes-demarches.gov.pf/matomo/index.php?module=CoreAdminHome&action=optOut&language=fr&backgroundColor=ffffff&fontColor=333333&fontSize=16px&fontFamily=Muli'
