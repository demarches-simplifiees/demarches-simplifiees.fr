# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/bandeau-d-information-importante/
class Dsfr::NoticeComponent < ApplicationComponent
  renders_one :title

  def initialize(closable: false)
    @closable = closable
  end

  def closable?
    !!@closable
  end
end
