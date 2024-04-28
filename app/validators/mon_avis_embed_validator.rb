# frozen_string_literal: true

# We need to ensure the embed code is not any random string in order to avoid injections
class MonAvisEmbedValidator < ActiveModel::Validator
  class MonAvisEmbedError < StandardError; end
  # from time to time, they decide to change domain just for fun. if it breaks, check the new subdomain
  KNOWN_SUBDOMAIN = ['jedonnemonavis', 'monavis', 'voxusagers']
  HREF_CHECKER = /https:\/\/#{KNOWN_SUBDOMAIN.join('|')}.numerique.gouv.fr\/Demarches\/\d+.*key=[[:alnum:]]+.*/
  IMG_CHECKER = /https:\/\/#{KNOWN_SUBDOMAIN.join('|')}.numerique.gouv.fr\/(monavis-)?static\/bouton-blanc|bleu.png|svg/

  def validate(record)
    if record.monavis_embed.present?
      embed = Nokogiri::HTML(record.monavis_embed)
      check_link(embed.css('a'))
      check_img(embed.css('img'))
    end
  rescue MonAvisEmbedError => e
    record.errors.add :monavis_embed, :invalid, message: "Le code fourni ne correspond pas au format des codes MonAvis reconnus par la plateforme. #{e.message}"
  rescue # nokogiri
    record.errors.add :monavis_embed, :invalid, message: "Le code fourni ne correspond pas au format des codes MonAvis reconnus par la plateforme."
  end

  def check_link(links)
    raise MonAvisEmbedError.new("le code monavis doit comporter un seul lien") if links.size != 1
    raise MonAvisEmbedError.new("le lien du bouton mon avis doit pointer vers le bon domaine") if !HREF_CHECKER.match?(links.first['href'])
  end

  def check_img(imgs)
    raise MonAvisEmbedError.new("le code monavis doit comporter une seule image") if imgs.size != 1
    raise MonAvisEmbedError.new("l'image du bouton mon avis ne pointe pas vers le bon domaine") if !IMG_CHECKER.match?(imgs.first['src'])
    raise MonAvisEmbedError.new("l'image du bouton mon avis n'a pas d'attribut alt") if imgs.first['alt'].blank?
  end
end
