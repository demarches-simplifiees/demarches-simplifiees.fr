class DemoController < ApplicationController

  def index
    @procedures = Procedure.all.where(archived: false).order('libelle ASC')
  end

end
