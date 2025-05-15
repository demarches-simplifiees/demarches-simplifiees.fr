#---------------------------------------------------------------------------------
# Build node_modules dependencies using Bun image
#---------------------------------------------------------------------------------
FROM oven/bun:1 as bun
WORKDIR /app
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile --production

#--------------------------------------------------
# Builder
# Intermediate container to bundle all gems
# Building gems requires dev librairies we don't need in production container
#--------------------------------------------------
FROM ruby:3.3.0-slim AS base
FROM base AS builder

RUN apt-get update && \
    curl -sL "https://deb.nodesource.com/setup_18.x" | bash - && \
      apt-get install -y curl build-essential git libpq-dev libicu-dev gnupg zip nodejs

ENV INSTALL_PATH /app
RUN mkdir -p ${INSTALL_PATH}
WORKDIR ${INSTALL_PATH}
COPY Gemfile Gemfile.lock ./

# sassc https://github.com/sass/sassc-ruby/issues/146#issuecomment-608489863
RUN bundle config specific_platform x86_64-linux \
  && bundle config build.sassc --disable-march-tune-native \
    && bundle config deployment true \
       && bundle config without "development test" \
         && bundle install

#---------------------------------------------------------------------------------
#  App/Worker container
#---------------------------------------------------------------------------------
FROM base
ENV APP_PATH /app
#----- minimum set of packages
RUN apt-get update && apt-get install -y curl git postgresql-client libicu72 poppler-utils imagemagick ghostscript gnupg zip
RUN (curl -sL "https://deb.nodesource.com/setup_18.x" | bash -) \
      && apt-get install -y nodejs

RUN adduser --disabled-password --home ${APP_PATH} userapp
USER userapp
WORKDIR ${APP_PATH}

#----- Building js dependencies (node_modules)
RUN (curl -fsSL https://bun.sh/install | bash)
COPY package.json bun.lockb ./
COPY --chown=userapp:userapp --from=bun /app/node_modules ${APP_PATH}/node_modules
COPY patches ./patches/
RUN .bun/bin/bun install

#----- Bundle gems: copy from builder container the dependency gems
#cf https://imagetragick.com/
ADD image_magick_policy.xml /etc/ImageMagick-6/policy.xml
COPY --chown=userapp:userapp --from=builder /app ${APP_PATH}/

RUN bundle config specific_platform x86_64-linux \
      && bundle config build.sassc --disable-march-tune-native \
        && bundle config deployment true \
          && bundle config without "development test" \
            && bundle install

ENV \
    ACTIVE_STORAGE_SERVICE="s3"\
    AGENT_CONNECT_ENABLED=""\
    AGENT_CONNECT_ID=""\
    AGENT_CONNECT_SECRET=""\
    AGENT_CONNECT_BASE_URL=""\
    AGENT_CONNECT_JWKS=""\
    AGENT_CONNECT_REDIRECT=""\
    API_ADRESSE_URL="https://api-adresse.data.gouv.fr"\
    API_COJO_URL=""\
    API_CPS_AUTH=""\
    API_CPS_CLIENT_ID=""\
    API_CPS_CLIENT_SECRET=""\
    API_CPS_PASSWORD=""\
    API_CPS_URL=""\
    API_CPS_USERNAME=""\
    API_EDUCATION_URL="https://data.education.gouv.fr/api/records/1.0"\
    API_ENTREPRISE_DEFAULT_SIRET=""\
    API_ENTREPRISE_KEY=""\
    API_ISPF_AUTH_URL=""\
    API_ISPF_URL=""\
    API_GEO_URL="https://geo.api.gouv.fr"\
    API_ISPF_PASSWORD=""\
    API_ISPF_USER=""\
    APPLICATION_BASE_URL="https://www.mes-demarches.gov.pf"\
    APPLICATION_NAME="Mes-Démarches"\
    APP_HOST="localhost:3000"\
    APP_NAME="tps_local"\
    AR_ENCRYPTION_KEY_DERIVATION_SALT=""\
    AR_ENCRYPTION_PRIMARY_KEY=""\
    BASIC_AUTH_ENABLED="disabled"\
    BASIC_AUTH_PASSWORD=""\
    BASIC_AUTH_USERNAME=""\
    CARRIERWAVE_CACHE_DIR="$APP_PATH/tmp/carrierwave"\
    CLAMAV_ENABLED="disabled"\
    COJO_JWT_RSA_PRIVATE_KEY=""\
    CRISP_CLIENT_KEY=""\
    CRISP_ENABLED="disabled"\
    DB_DATABASE="tps"\
    DB_HOST="localhost"\
    DB_PASSWORD="tps"\
    DB_POOL="50"\
    DB_USERNAME="tps"\
    DEMANDE_INSCRIPTION_ADMIN_PAGE_URL="https://www.mes-demarches.gov.pf/commencer/dmra-devenir-administrateur-de-demarches-en-ligne"\
    DOLIST_BALANCING_VALUE=""\
    DOLIST_USERNAME=""\
    DOLIST_PASSWORD=""\
    DOLIST_ACCOUNT_ID=""\
    DOLIST_API_KEY=""\
    DOC_URL="https://mes-demarches.gitbook.io/documentation"\
    DS_PROXY_URL=""\
    ENCRYPTION_SERVICE_SALT=""\
    FACEBOOK_CLIENT_ID=""\
    FACEBOOK_CLIENT_SECRET=""\
    FAVICON_16PX_SRC="favicons/pf16x16.png"\
    FAVICON_32PX_SRC="favicons/pf32x32.png"\
    FAVICON_96PX_SRC="favicons/pf96x96.png"\
    FC_PARTICULIER_BASE_URL=""\
    FC_PARTICULIER_ID=""\
    FC_PARTICULIER_SECRET=""\
    FOG_DIRECTORY=""\
    FOG_ENABLED=""\
    FOG_OPENSTACK_API_KEY=""\
    FOG_OPENSTACK_AUTH_URL=""\
    FOG_OPENSTACK_IDENTITY_API_VERSION=""\
    FOG_OPENSTACK_REGION=""\
    FOG_OPENSTACK_TENANT=""\
    FOG_OPENSTACK_URL=""\
    FOG_OPENSTACK_USERNAME=""\
    GITHUB_CLIENT_ID=""\
    GITHUB_CLIENT_SECRET=""\
    GOOGLE_CLIENT_ID=""\
    GOOGLE_CLIENT_SECRET=""\
    HELPSCOUT_CLIENT_ID=""\
    HELPSCOUT_CLIENT_SECRET=""\
    HELPSCOUT_MAILBOX_ID=""\
    HELPSCOUT_WEBHOOK_SECRET=""\
    INVISIBLE_CAPTCHA_SECRET="pwd"\
    LEGIT_ADMIN_DOMAINS="gov.pf"\
    LOGRAGE_ENABLED="disabled"\
    LOGRAGE_SOURCE=""\
    MAILCATCHER_ENABLED="disabled"\
    MAILCATCHER_HOST=""\
    MAILCATCHER_PORT=""\
    MAILER_LOGO_SRC="header/logo-md-wide.png"\
    MAILJET_API_KEY=""\
    MAILJET_SECRET_KEY=""\
    MAILTRAP_ENABLED="disabled"\
    MAILTRAP_PASSWORD=""\
    MAILTRAP_USERNAME=""\
    MATOMO_ENABLED="disabled"\
    MATOMO_COOKIE_DOMAIN="*.mes-demarches.gov.pf"\
    MATOMO_DOMAIN="*.mes-demarches.gov.pf"\
    MATOMO_HOST="beta.mes-demarches.gov.pf"\
    MATOMO_ID="1"\
    MATOMO_IFRAME_URL=""\
    MICROSOFT_CLIENT_ID=""\
    MICROSOFT_CLIENT_SECRET=""\
    OTP_SECRET_KEY="" \
    PATH="${PATH}:${APP_PATH}/.bun/bin"\
    PIPEDRIVE_KEY=""\
    PROCEDURE_DEFAULT_LOGO_SRC="polynesie.png"\
    RAILS_ENV="production"\
    RAILS_LOG_TO_STDOUT=""\
    RAILS_SERVE_STATIC_FILES=true\
    RUBY_YJIT_ENABLE=true\
    SAML_IDP_ENABLED=""\
    SAML_IDP_CERTIFICATE="billybop"\
    SAML_IDP_SECRET_KEY="-----BEGIN RSA PRIVATE KEY-----\nblabla+blabla\n-----END RSA PRIVATE KEY-----\n"\
    SECRET_KEY_BASE="05a2d479d8e412198dabd08ef0eee9d6e180f5cbb48661a35fd1cae287f0a93d40b5f1da08f06780d698bbd458a0ea97f730f83ee780de5d4e31f649a0130cf0"\
    S3_ENDPOINT="" \
    S3_BUCKET="" \
    S3_ACCESS_KEY="" \
    S3_SECRET_KEY="" \
    S3_REGION="" \
    SENDINBLUE_API_V3_KEY=""\
    SENDINBLUE_BALANCING_VALUE="100"\
    SENDINBLUE_CLIENT_KEY=""\
    SENDINBLUE_LOGIN_URL=""\
    SENDINBLUE_SMTP_KEY=""\
    SENDINBLUE_USER_NAME=""\
    SENTRY_CURRENT_ENV=""\
    SENTRY_DSN_JS=""\
    SENTRY_DSN_RAILS=""\
    SENTRY_ENABLED="disabled"\
    SIGNING_KEY="aef3153a9829fa4ba10acb02927ac855df6b92795b1ad265d654443c4b14a017"\
    SIPF_CLIENT_BASE_URL=""\
    SIPF_CLIENT_ID=""\
    SIPF_CLIENT_SECRET=""\
    SKYLIGHT_AUTHENTICATION_KEY=""\
    SKYLIGHT_DISABLE_AGENT="true"\
    SOURCE="tps_local"\
    STRICT_EMAIL_VALIDATION_STARTS_ON="2024-04-24"\
    TATOU_BASE_URL=""\
    TATOU_CLIENT_ID=""\
    TATOU_CLIENT_SECRET=""\
    TRUSTED_NETWORKS=""\
    CERTIGNA_USERPWD=""\
    WATERMARK_FILE="watermark_pf.png"\
    WEASYPRINT_URL="http://weasyprint:5000/pdf"\
    YAHOO_CLIENT_ID=""\
    YAHOO_CLIENT_SECRET=""

COPY --chown=userapp:userapp . ${APP_PATH}
RUN rm -fr .git

#----- Precompile assets
RUN echo $PATH
RUN which bun
RUN RAILS_ENV=production NODE_OPTIONS=--max-old-space-size=4000 bundle exec rails assets:precompile

RUN chmod a+x $APP_PATH/app/lib/*.sh

EXPOSE 3000
ENTRYPOINT ["/app/app/lib/docker-entry-point.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]
