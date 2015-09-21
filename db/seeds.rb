# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Dir[File.join(Rails.root, 'db', 'seeds', '*.rb')].sort.each { |seed| load seed }

# puts "create links"
# TypePieceJointe.find_each do |type_piece_jointe|
#   forms = Formulaire.find_by_demarche_id(type_piece_jointe.CERFA)
#   type_piece_jointe.update_attributes(formulaire_id: forms.id) unless forms.nil?
# end
# puts "end links creation"
