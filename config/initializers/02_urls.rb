# rubocop:disable DS/ApplicationName
# API URLs
API_ADRESSE_URL = ENV.fetch("API_ADRESSE_URL", "https://api-adresse.data.gouv.fr")
API_ENTREPRISE_URL = ENV.fetch("API_ENTREPRISE_URL", "https://entreprise.api.gouv.fr")
API_EDUCATION_URL = ENV.fetch("API_EDUCATION_URL", "https://data.education.gouv.fr/api/records/1.0")
API_GEO_URL = ENV.fetch("API_GEO_URL", "https://geo.api.gouv.fr")
API_PARTICULIER_URL = ENV.fetch("API_PARTICULIER_URL", "https://particulier.api.gouv.fr/api")
API_TCHAP_URL = ENV.fetch("API_TCHAP_URL", "https://matrix.agent.tchap.gouv.fr/_matrix/identity/api/v1")
API_COJO_URL = ENV.fetch("API_COJO_URL", nil)
API_RNF_URL = ENV.fetch("API_RNF_URL", "https://rnf.dso.numerique-interieur.com")
API_RECHERCHE_ENTREPRISE_URL = ENV.fetch("API_RECHERCHE_ENTREPRISE_URL", "https://recherche-entreprises.api.gouv.fr")
HELPSCOUT_API_URL = ENV.fetch("HELPSCOUT_API_URL", "https://api.helpscout.net/v2")
SENDINBLUE_API_URL = ENV.fetch("SENDINBLUE_API_URL", "https://in-automate.sendinblue.com/api/v2")
SENDINBLUE_API_V3_URL = ENV.fetch("SENDINBLUE_API_V3_URL", "https://api.sendinblue.com/v3")
UNIVERSIGN_API_URL = ENV.fetch("UNIVERSIGN_API_URL", "https://ws.universign.eu/tsa/post/")
CERTIGNA_API_URL = ENV.fetch("CERTIGNA_API_URL", "https://timestamp.dhimyotis.com/api/v1/")
FEATURE_UPVOTE_URL = ENV.fetch("FEATURE_UPVOTE_URL", "https://demarches-simplifiees.featureupvote.com")
WEASYPRINT_URL = ENV.fetch("WEASYPRINT_URL", nil)

# Internal URLs
FOG_OPENSTACK_URL = ENV.fetch("FOG_OPENSTACK_URL", "https://auth.cloud.ovh.net")
DS_PROXY_URL = ENV.fetch("DS_PROXY_URL", "")
S3_ENDPOINT_URL = ENV.fetch("S3_ENDPOINT", "")

# External services URLs
WEBINAIRE_URL = "https://app.livestorm.co/demarches-simplifiees"
INSCRIPTION_WEBINAIRE_URL = "https://bbb-dinum-scalelite.visio.education.fr/playback/presentation/2.3/cbb6e43626fa1b67755d9fb05ecf5e7f3be50d48-1675342730585"
DEMO_VIDEO_URL = "https://webinaire.bbb-dinum-scalelite.visio.education.fr/playback/presentation/2.3/f7e68599a24f8d6cf38430076f989a53612cbd3f-1712231936831"
CALENDLY_URL = "https://calendly.com/demarches-simplifiees/accompagnement-administrateur-demarches-simplifiees-fr"

FR_SITE = 'demarches-simplifiees.fr'
FR_DOC_URL = "https://doc.#{FR_SITE}"
DOC_URL = ENV.fetch("DOC_URL", "https://mes-demarches.gitbook.io/documentation")
DOC_NOUVEAUTES_URL = [DOC_URL, "nouveautes"].join("/")
ADMINISTRATEUR_TUTORIAL_URL = [DOC_URL, "dematerialiser-un-formulaire-1", "tutoriels", "dematerialiser-formulaire"].join("/")
INSTRUCTEUR_TUTORIAL_URL = [DOC_URL, "dematerialiser-un-formulaire-1", "tutoriels"].join("/")
CADRE_JURIDIQUE_URL = [ADMINISTRATEUR_TUTORIAL_URL, "cadre-juridique"].join("#") # TODO version polynésie
LISTE_DES_DEMARCHES_URL = "https://www.service-public.pf/demarches-en-ligne"
CGU_URL = ENV.fetch("CGU_URL", [DOC_URL, "cgu"].join("/"))
MENTIONS_LEGALES_URL = ENV.fetch("MENTIONS_LEGALES_URL", "/mentions-legales")
ACCESSIBILITE_URL = ENV.fetch("ACCESSIBILITE_URL", "/declaration-accessibilite")
ROUTAGE_URL = ENV.fetch("ROUTAGE_URL", [FR_DOC_URL, "/pour-aller-plus-loin/routage"].join("/"))
ELIGIBILITE_URL = ENV.fetch("ELIGIBILITE_URL", [FR_DOC_URL, "/pour-aller-plus-loin/eligibilite-des-dossiers"].join("/"))
API_DOC_URL = [FR_DOC_URL, "api-graphql"].join("/")
WEBHOOK_DOC_URL = [FR_DOC_URL, "pour-aller-plus-loin", "webhook"].join("/")
WEBHOOK_ALTERNATIVE_DOC_URL = [FR_DOC_URL, "api-graphql", "cas-dusages-exemple-dimplementation", "synchroniser-les-dossiers-modifies-sur-ma-demarche"].join("/")
ARCHIVAGE_DOC_URL = [FR_DOC_URL, "pour-aller-plus-loin", "archivage-longue-duree-des-demarches"].join("/")
DOC_INTEGRATION_MONAVIS_URL = [FR_DOC_URL, "tutoriels", "integration-du-bouton-mon-avis"].join("/")
DOC_PROCEDURE_EXPIRES_URL = [FR_DOC_URL, "expiration-et-suppression-des-dossiers"].join("/")

STATUS_PAGE_URL = ENV.fetch("STATUS_PAGE_URL", "https://updown.io/cugq")
DEMANDE_INSCRIPTION_ADMIN_PAGE_URL = ENV.fetch("DEMANDE_INSCRIPTION_ADMIN_PAGE_URL", "https://www.demarches-simplifiees.fr/commencer/demande-d-inscription-a-demarches-simplifiees")
MATOMO_IFRAME_URL = ENV.fetch("MATOMO_IFRAME_URL", "https://#{ENV.fetch('MATOMO_HOST', 'stats.data.gouv.fr')}/index.php?module=CoreAdminHome&action=optOut&language=fr&&fontColor=333333&fontSize=16px&fontFamily=Muli")

#----- Polynesian variables

RGPD_URL = [CGU_URL, "rgpd"].join("#")

API_TE_FENUA_URL = ENV.fetch("API_TE_FENUA_URL", "https://www.tefenua.gov.pf/api")

API_ISPF_AUTH_URL = ENV.fetch("API_ISPF_AUTH_URL", "https://auth.gov.pf/auth/realms/Itaiete/protocol/openid-connect/token")
API_ISPF_URL = ENV.fetch("API_ISPF_URL", "https://api.gov.pf/i-taiete")

API_CPS_AUTH = ENV.fetch("API_CPS_AUTH", "https://connect.cps.pf/auth/realms/TatouAssures/protocol/openid-connect/token")
API_CPS_URL = ENV.fetch("API_CPS_URL", "https://tatouapi.cps.pf")

# rubocop:enable DS/ApplicationName
