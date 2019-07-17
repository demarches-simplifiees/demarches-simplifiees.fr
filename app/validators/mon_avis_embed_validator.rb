class MonAvisEmbedValidator < ActiveModel::Validator
  def validate(record)
    # We need to ensure the embed code is not any random string in order to avoid injections
    r = Regexp.new('<a href="https://monavis.numerique.gouv.fr/Demarches/\d+.*key=[[:alnum:]]+.*">\s*<img src="https://monavis.numerique.gouv.fr/monavis-static/bouton-blanc|bleu.png" alt="Je donne mon avis" title="Je donne mon avis sur cette démarche" />\s*</a>', Regexp::MULTILINE)
    if record.monavis_embed.present? && !r.match?(record.monavis_embed)
      record.errors[:base] << "Le code fourni ne correspond pas au format des codes MonAvis reconnus par la plateforme."
    end
  end
end
