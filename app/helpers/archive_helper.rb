module ArchiveHelper
  def can_generate_archive?(dossiers_termines, poids_total)
    dossiers_termines.count < 100 && poids_total < 1.gigabyte
  end
end
