FactoryBot.define do
  factory :agent_connect_information do
    email { 'i@agent_connect.fr' }
    given_name { 'John' }
    usual_name { 'Doe' }
    sub { '123456789' }
    siret { '12345678901234' }
    organizational_unit { 'Ministère A.M.E.R.' }
    belonging_population { 'stagiaire' }
    phone { '0123456789' }
  end
end
