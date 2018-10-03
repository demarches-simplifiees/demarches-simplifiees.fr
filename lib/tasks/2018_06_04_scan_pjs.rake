namespace :'2018_06_04_scan_pjs' do
  task scan_all: :environment do
    Champs::PieceJustificativeChamp.all.each(&:create_virus_scan)
  end
end
