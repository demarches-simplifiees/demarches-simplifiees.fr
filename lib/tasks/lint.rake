task :lint do
  sh "bundle exec rubocop"
  sh "bundle exec haml-lint app/views/"
  sh "bundle exec scss-lint app/assets/stylesheets/"
  sh "bundle exec brakeman --no-pager"
  sh "yarn lint:ec"
  sh "yarn lint:js"
end

namespace :accessibility do
  task :lint do
    sh "bundle exec rspec accessibility"
  end

  # The main task `lint` expects you to run the W3C server application
  # beforehand
  namespace :local_w3c_validator do
    task :start do
      sh "docker run -it --rm -p 8888:8888 validator/validator:latest"
    end
  end
end
