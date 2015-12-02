class DemoController < ApplicationController

  def index
    @procedures = Procedure.where(archived: false).order('libelle ASC')
  end

end
