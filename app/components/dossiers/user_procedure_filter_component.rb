class Dossiers::UserProcedureFilterComponent < ApplicationComponent
  include DossierHelper

  def initialize(dossiers:)
    @dossiers = dossiers
  end

  attr_reader :dossiers

  def procedures_collection(dossiers)
    dossiers.map do |dossier|
      [dossier.procedure.libelle, dossier.procedure.id]
    end.uniq
  end
end
