class SetOriginalFilenameForUploaders < ActiveRecord::Migration
  def change
    PieceJustificative.find_each do |pj|
      if pj.original_filename.nil?
        pj.original_filename = pj.content_identifier
        pj.save!
      end
    end

    Cerfa.find_each do |cerfa|
      if cerfa.original_filename.nil?
        cerfa.original_filename = cerfa.content_identifier
        cerfa.save!
      end
    end
  end
end
