task :lint do
  sh "bundle exec rubocop"
  sh "bundle exec haml-lint app/views/"
  sh "bundle exec scss-lint app/assets/stylesheets/"
  sh "bundle exec brakeman --no-pager"
  sh "yarn lint:ec"
  sh "yarn lint:js"
end
