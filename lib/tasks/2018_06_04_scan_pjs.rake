namespace :'2018_06_04_scan_pjs' do
  task scan_all: :environment do
    Champs::PieceJustificativeChamp.all.each do |pj_champ|
      pj_champ.create_virus_scan
    end
  end
end
