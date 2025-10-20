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
      fragment = Nokogiri::HTML::DocumentFragment.parse(record.monavis_embed)
      ensure_only_allowed_nodes!(fragment)
      check_link(fragment.css('a'))
      check_img(fragment.css('img'))
    end
  rescue MonAvisEmbedError => e
    record.errors.add :monavis_embed, :invalid, message: "Le code fourni ne correspond pas au format des codes MonAvis reconnus par la plateforme. #{e.message}"
  rescue # nokogiri
    record.errors.add :monavis_embed, :invalid, message: "Le code fourni ne correspond pas au format des codes MonAvis reconnus par la plateforme."
  end

  def check_link(links)
    raise MonAvisEmbedError.new("le code monavis doit comporter un seul lien") if links.size != 1
    href = links.first['href'].to_s.strip
    reject_dangerous_scheme!(href)
    raise MonAvisEmbedError.new("le lien du bouton mon avis doit pointer vers le bon domaine") unless HREF_CHECKER.match?(href)
  end

  def check_img(imgs)
    raise MonAvisEmbedError.new("le code monavis doit comporter une seule image") if imgs.size != 1
    img = imgs.first
    src = img['src'].to_s.strip
    reject_dangerous_scheme!(src)
    raise MonAvisEmbedError.new("l'image du bouton mon avis ne pointe pas vers le bon domaine") unless IMG_CHECKER.match?(src)
    raise MonAvisEmbedError.new("l'image du bouton mon avis n'a pas d'attribut alt") if img['alt'].blank?
  end

  private

  def ensure_only_allowed_nodes!(fragment)
    allowed_tags = %w[a img]
    allowed_attributes = %w[href src alt target rel]

    fragment.traverse do |node|
      if node.element?
        raise MonAvisEmbedError.new("élément interdit présent: #{node.name}") unless allowed_tags.include?(node.name)
        node.attribute_nodes.each do |attr|
          name = attr.name.to_s
          # reject event handlers and any non-allowed attributes
          raise MonAvisEmbedError.new("attribut non autorisé #{name}") unless allowed_attributes.include?(name)
        end
      else
        raise MonAvisEmbedError.new("contenu non autorisé dans le fragment")
      end
    end
  end

  def reject_dangerous_scheme!(value)
    v = value.to_s.strip
    raise MonAvisEmbedError.new("schéma d'URL non autorisé") if !/\A\s*(https:\/\/)/i.match?(v)
  end
end
