# complexity of the required password for the three kinds of users (user, gestionnaire, admnistrateur)
# valid values are from 0 to 4, 0 means very simple, 4 means high level of complexity.
if !defined?(PASSWORD_MIN_LENGTH)
  PASSWORD_COMPLEXITY_FOR_USER = ENV.fetch('PASSWORD_COMPLEXITY_FOR_USER', '2').to_i
  PASSWORD_COMPLEXITY_FOR_GESTIONNAIRE = ENV.fetch('PASSWORD_COMPLEXITY_FOR_GESTIONNAIRE', '3').to_i
  PASSWORD_COMPLEXITY_FOR_ADMIN = ENV.fetch('PASSWORD_COMPLEXITY_FOR_ADMIN', '4').to_i
  # password minimum length
  PASSWORD_MIN_LENGTH = ENV.fetch('PASSWORD_MIN_LENGTH', '8').to_i
end
