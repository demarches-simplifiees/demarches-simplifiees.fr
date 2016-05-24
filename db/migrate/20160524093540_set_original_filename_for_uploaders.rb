class SetOriginalFilenameForUploaders < ActiveRecord::Migration
  class PieceJustificative < ActiveRecord::Base

  end

  class Cerfa < ActiveRecord::Base

  end

  def change
    PieceJustificative.all.each do |pj|
      if pj.original_filename.nil?
        pj.original_filename = pj.content
        pj.save!
      end
    end

    Cerfa.all.each do |cerfa|
      if cerfa.original_filename.nil?
        cerfa.original_filename = cerfa.content
        cerfa.save!
      end
    end
  end
end
