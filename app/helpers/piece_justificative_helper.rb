module PieceJustificativeHelper
  def display_pj_filename(pj)
    truncate(pj.original_filename, length: 60)
  end
end
