task :lint do
  sh "bundle exec rubocop --parallel"
  sh "bundle exec haml-lint app/views/"
  sh "bundle exec scss-lint app/assets/stylesheets/"
  sh "bundle exec i18n-tasks missing --locales fr"
  sh "bundle exec i18n-tasks unused --locale en" # TODO: check for all locales
  sh "bundle exec i18n-tasks check-consistent-interpolations"
  sh "bundle exec brakeman --no-pager"
  sh "yarn lint:js"
end
