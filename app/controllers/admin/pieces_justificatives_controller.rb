class Admin::PiecesJustificativesController < AdminController

  def edit
    @procedure = Procedure.find(params[:procedure_id])
    @types_de_piece_justificative = @procedure.types_de_piece_justificative
  end
end