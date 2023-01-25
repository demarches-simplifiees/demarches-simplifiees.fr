class TypesDeChamp::EmailTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def pattern
    "^\S+@\S+\.[a-zA-Z]{2,}$"
  end
end
