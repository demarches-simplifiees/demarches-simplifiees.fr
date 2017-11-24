module DossierHelper
  def label_class(dossier)
    if dossier.closed?
      'accepted'
    elsif dossier.without_continuation?
      'without-continuation'
    elsif dossier.refused?
      'refused'
    end
  end
end
