# API URLs
API_ADRESSE_URL = ENV.fetch("API_ADRESSE_URL", "https://api-adresse.data.gouv.fr")
API_CARTO_URL = ENV.fetch("API_CARTO_URL", "https://apicarto.sgmap.fr")
API_ENTREPRISE_URL = ENV.fetch("API_ENTREPRISE_URL", "https://entreprise.api.gouv.fr/v2")
API_GEO_URL = ENV.fetch("API_GEO_URL", "https://geo.api.gouv.fr")
API_GEO_SANDBOX_URL = ENV.fetch("API_GEO_SANDBOX_URL", "https://sandbox.geo.api.gouv.fr")
HELPSCOUT_API_URL = ENV.fetch("HELPSCOUT_API_URL", "https://api.helpscout.net/v2")
PIPEDRIVE_API_URL = ENV.fetch("PIPEDRIVE_API_URL", "https://api.pipedrive.com/v1")
SENDINBLUE_API_URL = ENV.fetch("SENDINBLUE_API_URL", "https://in-automate.sendinblue.com/api/v2")
UNIVERSIGN_API_URL = ENV.fetch("UNIVERSIGN_API_URL", "https://ws.universign.eu/tsa/post/")

API_ENTREPRISE_PF_URL = ENV.fetch("API_ENTREPRISE_PF_URL", "https://ppr.api.i-taiete2.gov.pf/api/v2")

# Internal URLs
FOG_BASE_URL = "https://static.demarches-simplifiees.fr"

# External services URLs
FR_DOC_URL = "https://doc.demarches-simplifiees.fr"
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
FAQ_ADMIN_URL = "https://faq.demarches-simplifiees.fr/collection/1-administrateur"
COMMENT_TROUVER_MA_DEMARCHE_URL = [FAQ_URL, 'pages', 'viewpage.action?pageId=24250654'].join("/")
STATUS_PAGE_URL = "https://updown.io/cugq"
MATOMO_URL = 'https://beta.mes-demarches.gov.pf/matomo'

# FIXME: This is only used in dev in couple of places and should be removed after PJ migration
LOCAL_DOWNLOAD_URL = "http://#{ENV.fetch('APP_HOST', 'localhost:3000')}"
