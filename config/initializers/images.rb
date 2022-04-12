# Favicons
FAVICON_16PX_SRC = ENV.fetch("FAVICON_16PX_SRC", "favicons/16x16.png")
FAVICON_32PX_SRC = ENV.fetch("FAVICON_32PX_SRC", "favicons/32x32.png")
FAVICON_96PX_SRC = ENV.fetch("FAVICON_96PX_SRC", "favicons/96x96.png")

# Header logo
HEADER_LOGO_SRC = ENV.fetch("HEADER_LOGO_SRC", "marianne.png")
HEADER_LOGO_ALT = ENV.fetch("HEADER_LOGO_ALT", "Liberté, égalité, fraternité")
HEADER_LOGO_WIDTH = ENV.fetch("HEADER_LOGO_WIDTH", "65")
HEADER_LOGO_HEIGHT = ENV.fetch("HEADER_LOGO_HEIGHT", "56")

# Mailer logos
MAILER_LOGO_SRC = ENV.fetch("MAILER_LOGO_SRC", "mailer/instructeur_mailer/logo.png")
MAILER_FOOTER_LOGO_SRC = ENV.fetch("MAILER_FOOTER_LOGO_SRC", "mailer/instructeur_mailer/logo-beta-gouv-fr.png")

# Default logo of a procedure
PROCEDURE_DEFAULT_LOGO_SRC = ENV.fetch("PROCEDURE_DEFAULT_LOGO_SRC", "republique-francaise-logo.svg")

# Logo in PDF export of a "Dossier"
DOSSIER_PDF_EXPORT_LOGO_SRC = ENV.fetch("DOSSIER_PDF_EXPORT_LOGO_SRC", "app/assets/images/header/logo-ds-wide.png")
