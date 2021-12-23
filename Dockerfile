FROM ruby:2.7.1-alpine AS base

#------------ intermediate container with specific dev tools
FROM base AS builder
# RUN ping -c 2 dl-cdn.alpinelinux.org
# RUN wget  --debug --verbose  http://dl-cdn.alpinelinux.org/alpine/v3.8/main/x86_64/APKINDEX.tar.gz
RUN apk add --update --virtual build-dependencies \
        build-base \
        imagemagick \
        file \
        gcc \
        git \
        icu \
        libcurl \
        curl-dev \
        postgresql-dev \
        yarn \
        python3
ENV INSTALL_PATH /app
RUN mkdir -p ${INSTALL_PATH}
COPY Gemfile Gemfile.lock package.json yarn.lock  ${INSTALL_PATH}/
WORKDIR ${INSTALL_PATH}

# sassc https://github.com/sass/sassc-ruby/issues/146#issuecomment-608489863
RUN bundle config specific_platform x86_64-linux \
  && bundle config --local build.sassc --disable-march-tune-native

RUN bundle config --global frozen 1 &&\
    bundle install --deployment --without development test&&\
    yarn install --production

#----------- final tps
FROM base
ENV APP_PATH /app
#----- minimum set of packages including PostgreSQL client, yarn
RUN apk add --no-cache --update tzdata libcurl postgresql-libs yarn imagemagick icu

WORKDIR ${APP_PATH}
RUN adduser -Dh ${APP_PATH} userapp

#----- copy from previous container the dependency gems plus the current application files
USER userapp

COPY --chown=userapp:userapp --from=builder /app ${APP_PATH}/
RUN bundle install --deployment --without development test && \
    rm -fr .git && \
    yarn install --production

ENV \
    AGENT_CONNECT_ENABLED=""\
    AGENT_CONNECT_ID=""\
    AGENT_CONNECT_SECRET=""\
    AGENT_CONNECT_BASE_URL=""\
    AGENT_CONNECT_JWKS=""\
    AGENT_CONNECT_REDIRECT=""\
    API_ADRESSE_URL="https://api-adresse.data.gouv.fr"\
    API_CPS_AUTH=""\
    API_CPS_CLIENT_ID=""\
    API_CPS_CLIENT_SECRET=""\
    API_CPS_PASSWORD=""\
    API_CPS_URL=""\
    API_CPS_USERNAME=""\
    API_EDUCATION_URL="https://data.education.gouv.fr/api/records/1.0"\
    API_ENTREPRISE_KEY=""\
    API_ENTREPRISE_PF_AUTH=""\
    API_ENTREPRISE_PF_URL=""\
    API_GEO_URL="https://geo.api.gouv.fr"\
    API_ISPF_PASSWORD=""\
    API_ISPF_USER=""\
    APPLICATION_BASE_URL="https://www.mes-demarches.gov.pf"\
    APPLICATION_NAME="Mes-Démarches"\
    APP_HOST="localhost:3000"\
    APP_NAME="tps_local"\
    BASIC_AUTH_ENABLED="disabled"\
    BASIC_AUTH_PASSWORD=""\
    BASIC_AUTH_USERNAME=""\
    CARRIERWAVE_CACHE_DIR="$APP_PATH/tmp/carrierwave"\
    CRISP_CLIENT_KEY=""\
    CRISP_ENABLED="disabled"\
    DB_DATABASE="tps"\
    DB_HOST="localhost"\
    DB_PASSWORD="tps"\
    DB_POOL="50"\
    DB_USERNAME="tps"\
    DEMANDE_INSCRIPTION_ADMIN_PAGE_URL="https://www.mes-demarches.gov.pf/commencer/dmra-devenir-administrateur-de-demarches-en-ligne"\
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
    LOGRAGE_ENABLED="disabled"\
    MAILER_LOGO_SRC="header/logo-md-wide.png"\
    MAILJET_API_KEY=""\
    MAILJET_SECRET_KEY=""\
    MAILTRAP_ENABLED="disabled"\
    MAILTRAP_PASSWORD=""\
    MAILTRAP_USERNAME=""\
    MATOMO_ENABLED="disabled"\
    MATOMO_ID="73"\
    MICROSOFT_CLIENT_ID=""\
    MICROSOFT_CLIENT_SECRET=""\
    OTP_SECRET_KEY="" \
    OUTSCALE_STEP="0" \
    PIPEDRIVE_KEY=""\
    PROCEDURE_DEFAULT_LOGO_SRC="polynesie.png"\
    RAILS_ENV="production"\
    RAILS_LOG_TO_STDOUT=""\
    RAILS_SERVE_STATIC_FILES=true\
    SAML_IDP_CERTIFICATE="billybop"\
    SAML_IDP_SECRET_KEY="-----BEGIN RSA PRIVATE KEY-----\nblabla+blabla\n-----END RSA PRIVATE KEY-----\n"\
    SECRET_KEY_BASE="05a2d479d8e412198dabd08ef0eee9d6e180f5cbb48661a35fd1cae287f0a93d40b5f1da08f06780d698bbd458a0ea97f730f83ee780de5d4e31f649a0130cf0"\
    S3_ENDPOINT="" \
    S3_BUCKET="" \
    S3_ACCESS_KEY="" \
    S3_SECRET_KEY="" \
    S3_REGION="" \
    SENDINBLUE_API_V3_KEY=""\
    SENDINBLUE_BALANCING=""\
    SENDINBLUE_BALANCING_VALUE=""\
    SENDINBLUE_ENABLED="disabled"\
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
    TATOU_BASE_URL=""\
    TATOU_CLIENT_ID=""\
    TATOU_CLIENT_SECRET=""\
    TRUSTED_NETWORKS=""\
    UNIVERSIGN_API_URL="https://ws.universign.eu/tsa/post/"\
    UNIVERSIGN_USERPWD=""\
    WATERMARK_FILE="watermark_pf.png"\
    YAHOO_CLIENT_ID=""\
    YAHOO_CLIENT_SECRET=""

COPY --chown=userapp:userapp . ${APP_PATH}
RUN RAILS_ENV=production bundle exec rails assets:precompile

RUN chmod a+x $APP_PATH/app/lib/docker-entry-point.sh

EXPOSE 3000
ENTRYPOINT ["/app/app/lib/docker-entry-point.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]
