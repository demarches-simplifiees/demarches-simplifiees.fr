# frozen_string_literal: true

FactoryBot.define do
  factory :pro_connect_information do
    user
    email { 'i@pro_connect.fr' }
    given_name { 'John' }
    usual_name { 'Doe' }
    sub { '123456789' }
    siret { '12345678901234' }
    organizational_unit { 'Ministère A.M.E.R.' }
    belonging_population { 'stagiaire' }
    phone { '0123456789' }
  end
end
