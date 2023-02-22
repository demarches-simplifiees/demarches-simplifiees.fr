# frozen_string_literal: true

module DossierPrefillableConcern
  extend ActiveSupport::Concern

  def prefill!(champs_public_attributes)
    return unless champs_public_attributes.any?

    attr = { prefilled: true }
    attr[:champs_public_all_attributes] = champs_public_attributes.map { |h| h.merge(prefilled: true) }

    assign_attributes(attr)
    save(validate: false)
  end
end


# Pour être sûr de bien être alignés, on veut bien les format suivants ?

#     En POST, je prends un hash classique et je lui fais to_json
#     Pour ton exemple ça donne: "{\"champ_id1\":\"text\",\"champ_id2\":[\"option1\",\"option2\"],\"champ_id3\":[{\"champ_id4\":\"text\",\"champ_id5\":true,\"champ_id6\":42,\"champ_id7\":[\"option1\",\"option2\"]},{\"champ_id4\":\"text2\",\"champ_id6\":32}]}"

#     En GET, je prends un hash et je lui applique to_query
#     Pour ton exemple, et en escapant les caractères spéciaux: "champ_id1=text&champ_id2[]=option1&champ_id2[]=option2&champ_id3[][champ_id4]=text&champ_id3[][champ_id5]=true&champ_id3[][champ_id6]=42&champ_id3[][champ_id7][]=option1&champ_id3[][champ_id7][]=option2&champ_id3[][champ_id4]=text2&champ_id3[][champ_id6]=32"

#Tu confirmes ? Je préfère checker car c'est un tout petit peu différent de ton exemple
