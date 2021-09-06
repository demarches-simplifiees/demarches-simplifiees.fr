task :lint do
  sh "bundle exec rubocop --parallel"
  sh "bundle exec haml-lint app/views/"
  sh "bundle exec scss-lint app/assets/stylesheets/"
  sh "bundle exec brakeman --no-pager"
  sh "yarn lint:js"
end
