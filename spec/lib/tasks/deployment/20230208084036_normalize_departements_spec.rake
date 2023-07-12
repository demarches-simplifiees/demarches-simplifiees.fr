# frozen_string_literal: true

RSpec.describe '20230208084036_normalize_departements', vcr: { cassette_name: 'api_geo_departements' } do
  let(:champ) { create(:champ_departements) }
  let(:rake_task) { Rake::Task['after_party:normalize_departements'] }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  subject(:run_task) { perform_enqueued_jobs { rake_task.invoke } }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  after { rake_task.reenable }

  shared_examples "a non-changer" do |external_id, value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.not_to change { champ.reload.external_id } }

    it { expect { run_task }.not_to change { champ.reload.value } }
  end

  shared_examples "an external_id nullifier" do |external_id, value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.to change { champ.reload.external_id }.from(external_id).to(nil) }

    it { expect { run_task }.not_to change { champ.reload.value } }
  end

  shared_examples "a value nullifier" do |external_id, value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.not_to change { champ.reload.external_id } }

    it { expect { run_task }.to change { champ.reload.value }.from(value).to(nil) }
  end

  shared_examples "an external_id and value nullifier" do |external_id, value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.to change { champ.reload.external_id }.from(external_id).to(nil) }

    it { expect { run_task }.to change { champ.reload.value }.from(value).to(nil) }
  end

  shared_examples "an external_id updater" do |external_id, value, expected_external_id|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.to change { champ.reload.external_id }.from(external_id).to(expected_external_id) }

    it { expect { run_task }.not_to change { champ.reload.value } }
  end

  shared_examples "a value updater" do |external_id, value, expected_value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.not_to change { champ.reload.external_id } }

    it { expect { run_task }.to change { champ.reload.value }.from(value).to(expected_value) }
  end

  shared_examples "an external_id and value updater" do |external_id, value, expected_external_id, expected_value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.to change { champ.reload.external_id }.from(external_id).to(expected_external_id) }

    it { expect { run_task }.to change { champ.reload.value }.from(value).to(expected_value) }
  end

  shared_examples "a result checker" do |external_id, value, expected_external_id, expected_value|
    before do
      champ.update_columns(external_id:, value:)
      run_task
    end

    it { expect(champ.reload.external_id).to eq(expected_external_id) }

    it { expect(champ.reload.value).to eq(expected_value) }
  end

  it_behaves_like "a non-changer", nil, nil
  it_behaves_like "an external_id nullifier", '', nil
  it_behaves_like "a value nullifier", nil, ''
  it_behaves_like "an external_id and value nullifier", '', ''
  it_behaves_like "an external_id updater", nil, 'Ain', '01'
  it_behaves_like "an external_id updater", '', 'Ain', '01'
  it_behaves_like "a value updater", '01', nil, 'Ain'
  it_behaves_like "a value updater", '01', '', 'Ain'
  it_behaves_like "an external_id and value updater", nil, '01 - Ain', '01', 'Ain'
  it_behaves_like "an external_id and value updater", '', '01 - Ain', '01', 'Ain'

  # Integrity data check:
  it_behaves_like "a result checker", "972", nil, "972", "Martinique"
  it_behaves_like "a result checker", "92", nil, "92", "Hauts-de-Seine"
  it_behaves_like "a result checker", "01", nil, "01", "Ain"
  it_behaves_like "a result checker", "82", nil, "82", "Tarn-et-Garonne"
  it_behaves_like "a result checker", "01", "01 - Ain", "01", "Ain"
  it_behaves_like "a result checker", '', "01 - Ain", "01", "Ain"
  it_behaves_like "a result checker", nil, "01 - Ain", "01", "Ain"
  it_behaves_like "a result checker", "02", "02 - Aisne", "02", "Aisne"
  it_behaves_like "a result checker", nil, "02 - Aisne", "02", "Aisne"
  it_behaves_like "a result checker", '', "02 - Aisne", "02", "Aisne"
  it_behaves_like "a result checker", "03", "03 - Allier", "03", "Allier"
  it_behaves_like "a result checker", nil, "03 - Allier", "03", "Allier"
  it_behaves_like "a result checker", '', "03 - Allier", "03", "Allier"
  it_behaves_like "a result checker", "04", "04 - Alpes-de-Haute-Provence", "04", "Alpes-de-Haute-Provence"
  it_behaves_like "a result checker", nil, "04 - Alpes-de-Haute-Provence", "04", "Alpes-de-Haute-Provence"
  it_behaves_like "a result checker", '', "04 - Alpes-de-Haute-Provence", "04", "Alpes-de-Haute-Provence"
  it_behaves_like "a result checker", "05", "05 - Hautes-Alpes", "05", "Hautes-Alpes"
  it_behaves_like "a result checker", nil, "05 - Hautes-Alpes", "05", "Hautes-Alpes"
  it_behaves_like "a result checker", '', "05 - Hautes-Alpes", "05", "Hautes-Alpes"
  it_behaves_like "a result checker", nil, "06 - Alpes-Maritimes", "06", "Alpes-Maritimes"
  it_behaves_like "a result checker", "06", "06 - Alpes-Maritimes", "06", "Alpes-Maritimes"
  it_behaves_like "a result checker", '', "06 - Alpes-Maritimes", "06", "Alpes-Maritimes"
  it_behaves_like "a result checker", "07", "07 - Ardèche", "07", "Ardèche"
  it_behaves_like "a result checker", nil, "07 - Ardèche", "07", "Ardèche"
  it_behaves_like "a result checker", '', "07 - Ardèche", "07", "Ardèche"
  it_behaves_like "a result checker", "08", "08 - Ardennes", "08", "Ardennes"
  it_behaves_like "a result checker", nil, "08 - Ardennes", "08", "Ardennes"
  it_behaves_like "a result checker", '', "08 - Ardennes", "08", "Ardennes"
  it_behaves_like "a result checker", "09", "09 - Ariège", "09", "Ariège"
  it_behaves_like "a result checker", nil, "09 - Ariège", "09", "Ariège"
  it_behaves_like "a result checker", '', "09 - Ariège", "09", "Ariège"
  it_behaves_like "a result checker", nil, "10 - Aube", "10", "Aube"
  it_behaves_like "a result checker", "10", "10 - Aube", "10", "Aube"
  it_behaves_like "a result checker", '', "10 - Aube", "10", "Aube"
  it_behaves_like "a result checker", "11", "11 - Aude", "11", "Aude"
  it_behaves_like "a result checker", nil, "11 - Aude", "11", "Aude"
  it_behaves_like "a result checker", '', "11 - Aude", "11", "Aude"
  it_behaves_like "a result checker", "12", "12 - Aveyron", "12", "Aveyron"
  it_behaves_like "a result checker", nil, "12 - Aveyron", "12", "Aveyron"
  it_behaves_like "a result checker", '', "12 - Aveyron", "12", "Aveyron"
  it_behaves_like "a result checker", "13", "13 - Bouches-du-Rhône", "13", "Bouches-du-Rhône"
  it_behaves_like "a result checker", nil, "13 - Bouches-du-Rhône", "13", "Bouches-du-Rhône"
  it_behaves_like "a result checker", '', "13 - Bouches-du-Rhône", "13", "Bouches-du-Rhône"
  it_behaves_like "a result checker", "14", "14 - Calvados", "14", "Calvados"
  it_behaves_like "a result checker", nil, "14 - Calvados", "14", "Calvados"
  it_behaves_like "a result checker", '', "14 - Calvados", "14", "Calvados"
  it_behaves_like "a result checker", "15", "15 - Cantal", "15", "Cantal"
  it_behaves_like "a result checker", nil, "15 - Cantal", "15", "Cantal"
  it_behaves_like "a result checker", '', "15 - Cantal", "15", "Cantal"
  it_behaves_like "a result checker", "16", "16 - Charente", "16", "Charente"
  it_behaves_like "a result checker", nil, "16 - Charente", "16", "Charente"
  it_behaves_like "a result checker", '', "16 - Charente", "16", "Charente"
  it_behaves_like "a result checker", "17", "17 - Charente-Maritime", "17", "Charente-Maritime"
  it_behaves_like "a result checker", nil, "17 - Charente-Maritime", "17", "Charente-Maritime"
  it_behaves_like "a result checker", '', "17 - Charente-Maritime", "17", "Charente-Maritime"
  it_behaves_like "a result checker", "18", "18 - Cher", "18", "Cher"
  it_behaves_like "a result checker", nil, "18 - Cher", "18", "Cher"
  it_behaves_like "a result checker", '', "18 - Cher", "18", "Cher"
  it_behaves_like "a result checker", "19", "19 - Corrèze", "19", "Corrèze"
  it_behaves_like "a result checker", nil, "19 - Corrèze", "19", "Corrèze"
  it_behaves_like "a result checker", '', "19 - Corrèze", "19", "Corrèze"
  it_behaves_like "a result checker", "21", "21 - Côte-d’Or", "21", "Côte-d’Or"
  it_behaves_like "a result checker", '', "21 - Côte-d’Or", "21", "Côte-d’Or"
  it_behaves_like "a result checker", nil, "21 - Côte-d’Or", "21", "Côte-d’Or"
  it_behaves_like "a result checker", "22", "22 - Côtes-d’Armor", "22", "Côtes-d’Armor"
  it_behaves_like "a result checker", nil, "22 - Côtes-d’Armor", "22", "Côtes-d’Armor"
  it_behaves_like "a result checker", '', "22 - Côtes-d’Armor", "22", "Côtes-d’Armor"
  it_behaves_like "a result checker", "23", "23 - Creuse", "23", "Creuse"
  it_behaves_like "a result checker", nil, "23 - Creuse", "23", "Creuse"
  it_behaves_like "a result checker", '', "23 - Creuse", "23", "Creuse"
  it_behaves_like "a result checker", "24", "24 - Dordogne", "24", "Dordogne"
  it_behaves_like "a result checker", nil, "24 - Dordogne", "24", "Dordogne"
  it_behaves_like "a result checker", '', "24 - Dordogne", "24", "Dordogne"
  it_behaves_like "a result checker", "25", "25 - Doubs", "25", "Doubs"
  it_behaves_like "a result checker", nil, "25 - Doubs", "25", "Doubs"
  it_behaves_like "a result checker", '', "25 - Doubs", "25", "Doubs"
  it_behaves_like "a result checker", "26", "26 - Drôme", "26", "Drôme"
  it_behaves_like "a result checker", nil, "26 - Drôme", "26", "Drôme"
  it_behaves_like "a result checker", '', "26 - Drôme", "26", "Drôme"
  it_behaves_like "a result checker", "27", "27 - Eure", "27", "Eure"
  it_behaves_like "a result checker", nil, "27 - Eure", "27", "Eure"
  it_behaves_like "a result checker", '', "27 - Eure", "27", "Eure"
  it_behaves_like "a result checker", "28", "28 - Eure-et-Loir", "28", "Eure-et-Loir"
  it_behaves_like "a result checker", nil, "28 - Eure-et-Loir", "28", "Eure-et-Loir"
  it_behaves_like "a result checker", '', "28 - Eure-et-Loir", "28", "Eure-et-Loir"
  it_behaves_like "a result checker", "29", "29 - Finistère", "29", "Finistère"
  it_behaves_like "a result checker", nil, "29 - Finistère", "29", "Finistère"
  it_behaves_like "a result checker", '', "29 - Finistère", "29", "Finistère"
  it_behaves_like "a result checker", "2A", "2A - Corse-du-Sud", "2A", "Corse-du-Sud"
  it_behaves_like "a result checker", nil, "2A - Corse-du-Sud", "2A", "Corse-du-Sud"
  it_behaves_like "a result checker", '', "2A - Corse-du-Sud", "2A", "Corse-du-Sud"
  it_behaves_like "a result checker", "2B", "2B - Haute-Corse", "2B", "Haute-Corse"
  it_behaves_like "a result checker", nil, "2B - Haute-Corse", "2B", "Haute-Corse"
  it_behaves_like "a result checker", '', "2B - Haute-Corse", "2B", "Haute-Corse"
  it_behaves_like "a result checker", "30", "30 - Gard", "30", "Gard"
  it_behaves_like "a result checker", nil, "30 - Gard", "30", "Gard"
  it_behaves_like "a result checker", '', "30 - Gard", "30", "Gard"
  it_behaves_like "a result checker", "31", "31 - Haute-Garonne", "31", "Haute-Garonne"
  it_behaves_like "a result checker", nil, "31 - Haute-Garonne", "31", "Haute-Garonne"
  it_behaves_like "a result checker", '', "31 - Haute-Garonne", "31", "Haute-Garonne"
  it_behaves_like "a result checker", "32", "32 - Gers", "32", "Gers"
  it_behaves_like "a result checker", nil, "32 - Gers", "32", "Gers"
  it_behaves_like "a result checker", '', "32 - Gers", "32", "Gers"
  it_behaves_like "a result checker", "33", "33 - Gironde", "33", "Gironde"
  it_behaves_like "a result checker", nil, "33 - Gironde", "33", "Gironde"
  it_behaves_like "a result checker", '', "33 - Gironde", "33", "Gironde"
  it_behaves_like "a result checker", "34", "34 - Hérault", "34", "Hérault"
  it_behaves_like "a result checker", nil, "34 - Hérault", "34", "Hérault"
  it_behaves_like "a result checker", '', "34 - Hérault", "34", "Hérault"
  it_behaves_like "a result checker", "35", "35 - Ille-et-Vilaine", "35", "Ille-et-Vilaine"
  it_behaves_like "a result checker", nil, "35 - Ille-et-Vilaine", "35", "Ille-et-Vilaine"
  it_behaves_like "a result checker", '', "35 - Ille-et-Vilaine", "35", "Ille-et-Vilaine"
  it_behaves_like "a result checker", "36", "36 - Indre", "36", "Indre"
  it_behaves_like "a result checker", nil, "36 - Indre", "36", "Indre"
  it_behaves_like "a result checker", '', "36 - Indre", "36", "Indre"
  it_behaves_like "a result checker", "37", "37 - Indre-et-Loire", "37", "Indre-et-Loire"
  it_behaves_like "a result checker", nil, "37 - Indre-et-Loire", "37", "Indre-et-Loire"
  it_behaves_like "a result checker", '', "37 - Indre-et-Loire", "37", "Indre-et-Loire"
  it_behaves_like "a result checker", "38", "38 - Isère", "38", "Isère"
  it_behaves_like "a result checker", nil, "38 - Isère", "38", "Isère"
  it_behaves_like "a result checker", '', "38 - Isère", "38", "Isère"
  it_behaves_like "a result checker", "39", "39 - Jura", "39", "Jura"
  it_behaves_like "a result checker", nil, "39 - Jura", "39", "Jura"
  it_behaves_like "a result checker", '', "39 - Jura", "39", "Jura"
  it_behaves_like "a result checker", "40", "40 - Landes", "40", "Landes"
  it_behaves_like "a result checker", nil, "40 - Landes", "40", "Landes"
  it_behaves_like "a result checker", '', "40 - Landes", "40", "Landes"
  it_behaves_like "a result checker", "41", "41 - Loir-et-Cher", "41", "Loir-et-Cher"
  it_behaves_like "a result checker", nil, "41 - Loir-et-Cher", "41", "Loir-et-Cher"
  it_behaves_like "a result checker", '', "41 - Loir-et-Cher", "41", "Loir-et-Cher"
  it_behaves_like "a result checker", "42", "42 - Loire", "42", "Loire"
  it_behaves_like "a result checker", nil, "42 - Loire", "42", "Loire"
  it_behaves_like "a result checker", '', "42 - Loire", "42", "Loire"
  it_behaves_like "a result checker", "43", "43 - Haute-Loire", "43", "Haute-Loire"
  it_behaves_like "a result checker", nil, "43 - Haute-Loire", "43", "Haute-Loire"
  it_behaves_like "a result checker", '', "43 - Haute-Loire", "43", "Haute-Loire"
  it_behaves_like "a result checker", "44", "44 - Loire-Atlantique", "44", "Loire-Atlantique"
  it_behaves_like "a result checker", nil, "44 - Loire-Atlantique", "44", "Loire-Atlantique"
  it_behaves_like "a result checker", '', "44 - Loire-Atlantique", "44", "Loire-Atlantique"
  it_behaves_like "a result checker", "45", "45 - Loiret", "45", "Loiret"
  it_behaves_like "a result checker", nil, "45 - Loiret", "45", "Loiret"
  it_behaves_like "a result checker", '', "45 - Loiret", "45", "Loiret"
  it_behaves_like "a result checker", "46", "46 - Lot", "46", "Lot"
  it_behaves_like "a result checker", nil, "46 - Lot", "46", "Lot"
  it_behaves_like "a result checker", '', "46 - Lot", "46", "Lot"
  it_behaves_like "a result checker", "47", "47 - Lot-et-Garonne", "47", "Lot-et-Garonne"
  it_behaves_like "a result checker", nil, "47 - Lot-et-Garonne", "47", "Lot-et-Garonne"
  it_behaves_like "a result checker", '', "47 - Lot-et-Garonne", "47", "Lot-et-Garonne"
  it_behaves_like "a result checker", "48", "48 - Lozère", "48", "Lozère"
  it_behaves_like "a result checker", nil, "48 - Lozère", "48", "Lozère"
  it_behaves_like "a result checker", '', "48 - Lozère", "48", "Lozère"
  it_behaves_like "a result checker", "49", "49 - Maine-et-Loire", "49", "Maine-et-Loire"
  it_behaves_like "a result checker", nil, "49 - Maine-et-Loire", "49", "Maine-et-Loire"
  it_behaves_like "a result checker", '', "49 - Maine-et-Loire", "49", "Maine-et-Loire"
  it_behaves_like "a result checker", "50", "50 - Manche", "50", "Manche"
  it_behaves_like "a result checker", nil, "50 - Manche", "50", "Manche"
  it_behaves_like "a result checker", '', "50 - Manche", "50", "Manche"
  it_behaves_like "a result checker", "51", "51 - Marne", "51", "Marne"
  it_behaves_like "a result checker", '', "51 - Marne", "51", "Marne"
  it_behaves_like "a result checker", nil, "51 - Marne", "51", "Marne"
  it_behaves_like "a result checker", "52", "52 - Haute-Marne", "52", "Haute-Marne"
  it_behaves_like "a result checker", nil, "52 - Haute-Marne", "52", "Haute-Marne"
  it_behaves_like "a result checker", '', "52 - Haute-Marne", "52", "Haute-Marne"
  it_behaves_like "a result checker", "53", "53 - Mayenne", "53", "Mayenne"
  it_behaves_like "a result checker", nil, "53 - Mayenne", "53", "Mayenne"
  it_behaves_like "a result checker", '', "53 - Mayenne", "53", "Mayenne"
  it_behaves_like "a result checker", "54", "54 - Meurthe-et-Moselle", "54", "Meurthe-et-Moselle"
  it_behaves_like "a result checker", '', "54 - Meurthe-et-Moselle", "54", "Meurthe-et-Moselle"
  it_behaves_like "a result checker", nil, "54 - Meurthe-et-Moselle", "54", "Meurthe-et-Moselle"
  it_behaves_like "a result checker", nil, "55 - Meuse", "55", "Meuse"
  it_behaves_like "a result checker", "55", "55 - Meuse", "55", "Meuse"
  it_behaves_like "a result checker", '', "55 - Meuse", "55", "Meuse"
  it_behaves_like "a result checker", "56", "56 - Morbihan", "56", "Morbihan"
  it_behaves_like "a result checker", nil, "56 - Morbihan", "56", "Morbihan"
  it_behaves_like "a result checker", '', "56 - Morbihan", "56", "Morbihan"
  it_behaves_like "a result checker", "57", "57 - Moselle", "57", "Moselle"
  it_behaves_like "a result checker", nil, "57 - Moselle", "57", "Moselle"
  it_behaves_like "a result checker", '', "57 - Moselle", "57", "Moselle"
  it_behaves_like "a result checker", "58", "58 - Nièvre", "58", "Nièvre"
  it_behaves_like "a result checker", nil, "58 - Nièvre", "58", "Nièvre"
  it_behaves_like "a result checker", '', "58 - Nièvre", "58", "Nièvre"
  it_behaves_like "a result checker", "59", "59 - Nord", "59", "Nord"
  it_behaves_like "a result checker", nil, "59 - Nord", "59", "Nord"
  it_behaves_like "a result checker", '', "59 - Nord", "59", "Nord"
  it_behaves_like "a result checker", "60", "60 - Oise", "60", "Oise"
  it_behaves_like "a result checker", nil, "60 - Oise", "60", "Oise"
  it_behaves_like "a result checker", '', "60 - Oise", "60", "Oise"
  it_behaves_like "a result checker", "61", "61 - Orne", "61", "Orne"
  it_behaves_like "a result checker", nil, "61 - Orne", "61", "Orne"
  it_behaves_like "a result checker", '', "61 - Orne", "61", "Orne"
  it_behaves_like "a result checker", nil, "62 - Pas-de-Calais", "62", "Pas-de-Calais"
  it_behaves_like "a result checker", "62", "62 - Pas-de-Calais", "62", "Pas-de-Calais"
  it_behaves_like "a result checker", '', "62 - Pas-de-Calais", "62", "Pas-de-Calais"
  it_behaves_like "a result checker", "63", "63 - Puy-de-Dôme", "63", "Puy-de-Dôme"
  it_behaves_like "a result checker", nil, "63 - Puy-de-Dôme", "63", "Puy-de-Dôme"
  it_behaves_like "a result checker", '', "63 - Puy-de-Dôme", "63", "Puy-de-Dôme"
  it_behaves_like "a result checker", "64", "64 - Pyrénées-Atlantiques", "64", "Pyrénées-Atlantiques"
  it_behaves_like "a result checker", nil, "64 - Pyrénées-Atlantiques", "64", "Pyrénées-Atlantiques"
  it_behaves_like "a result checker", '', "64 - Pyrénées-Atlantiques", "64", "Pyrénées-Atlantiques"
  it_behaves_like "a result checker", "65", "65 - Hautes-Pyrénées", "65", "Hautes-Pyrénées"
  it_behaves_like "a result checker", nil, "65 - Hautes-Pyrénées", "65", "Hautes-Pyrénées"
  it_behaves_like "a result checker", '', "65 - Hautes-Pyrénées", "65", "Hautes-Pyrénées"
  it_behaves_like "a result checker", "66", "66 - Pyrénées-Orientales", "66", "Pyrénées-Orientales"
  it_behaves_like "a result checker", nil, "66 - Pyrénées-Orientales", "66", "Pyrénées-Orientales"
  it_behaves_like "a result checker", '', "66 - Pyrénées-Orientales", "66", "Pyrénées-Orientales"
  it_behaves_like "a result checker", "67", "67 - Bas-Rhin", "67", "Bas-Rhin"
  it_behaves_like "a result checker", nil, "67 - Bas-Rhin", "67", "Bas-Rhin"
  it_behaves_like "a result checker", '', "67 - Bas-Rhin", "67", "Bas-Rhin"
  it_behaves_like "a result checker", "68", "68 - Haut-Rhin", "68", "Haut-Rhin"
  it_behaves_like "a result checker", nil, "68 - Haut-Rhin", "68", "Haut-Rhin"
  it_behaves_like "a result checker", '', "68 - Haut-Rhin", "68", "Haut-Rhin"
  it_behaves_like "a result checker", "69", "69 - Rhône", "69", "Rhône"
  it_behaves_like "a result checker", nil, "69 - Rhône", "69", "Rhône"
  it_behaves_like "a result checker", '', "69 - Rhône", "69", "Rhône"
  it_behaves_like "a result checker", "70", "70 - Haute-Saône", "70", "Haute-Saône"
  it_behaves_like "a result checker", nil, "70 - Haute-Saône", "70", "Haute-Saône"
  it_behaves_like "a result checker", '', "70 - Haute-Saône", "70", "Haute-Saône"
  it_behaves_like "a result checker", "71", "71 - Saône-et-Loire", "71", "Saône-et-Loire"
  it_behaves_like "a result checker", nil, "71 - Saône-et-Loire", "71", "Saône-et-Loire"
  it_behaves_like "a result checker", '', "71 - Saône-et-Loire", "71", "Saône-et-Loire"
  it_behaves_like "a result checker", "72", "72 - Sarthe", "72", "Sarthe"
  it_behaves_like "a result checker", nil, "72 - Sarthe", "72", "Sarthe"
  it_behaves_like "a result checker", '', "72 - Sarthe", "72", "Sarthe"
  it_behaves_like "a result checker", "73", "73 - Savoie", "73", "Savoie"
  it_behaves_like "a result checker", nil, "73 - Savoie", "73", "Savoie"
  it_behaves_like "a result checker", '', "73 - Savoie", "73", "Savoie"
  it_behaves_like "a result checker", "74", "74 - Haute-Savoie", "74", "Haute-Savoie"
  it_behaves_like "a result checker", nil, "74 - Haute-Savoie", "74", "Haute-Savoie"
  it_behaves_like "a result checker", '', "74 - Haute-Savoie", "74", "Haute-Savoie"
  it_behaves_like "a result checker", "75", "75 - Paris", "75", "Paris"
  it_behaves_like "a result checker", nil, "75 - Paris", "75", "Paris"
  it_behaves_like "a result checker", '', "75 - Paris", "75", "Paris"
  it_behaves_like "a result checker", "76", "76 - Seine-Maritime", "76", "Seine-Maritime"
  it_behaves_like "a result checker", nil, "76 - Seine-Maritime", "76", "Seine-Maritime"
  it_behaves_like "a result checker", '', "76 - Seine-Maritime", "76", "Seine-Maritime"
  it_behaves_like "a result checker", "77", "77 - Seine-et-Marne", "77", "Seine-et-Marne"
  it_behaves_like "a result checker", nil, "77 - Seine-et-Marne", "77", "Seine-et-Marne"
  it_behaves_like "a result checker", '', "77 - Seine-et-Marne", "77", "Seine-et-Marne"
  it_behaves_like "a result checker", "78", "78 - Yvelines", "78", "Yvelines"
  it_behaves_like "a result checker", '', "78 - Yvelines", "78", "Yvelines"
  it_behaves_like "a result checker", nil, "78 - Yvelines", "78", "Yvelines"
  it_behaves_like "a result checker", "79", "79 - Deux-Sèvres", "79", "Deux-Sèvres"
  it_behaves_like "a result checker", nil, "79 - Deux-Sèvres", "79", "Deux-Sèvres"
  it_behaves_like "a result checker", '', "79 - Deux-Sèvres", "79", "Deux-Sèvres"
  it_behaves_like "a result checker", "80", "80 - Somme", "80", "Somme"
  it_behaves_like "a result checker", nil, "80 - Somme", "80", "Somme"
  it_behaves_like "a result checker", '', "80 - Somme", "80", "Somme"
  it_behaves_like "a result checker", "81", "81 - Tarn", "81", "Tarn"
  it_behaves_like "a result checker", '', "81 - Tarn", "81", "Tarn"
  it_behaves_like "a result checker", nil, "81 - Tarn", "81", "Tarn"
  it_behaves_like "a result checker", "82", "82 - Tarn-et-Garonne", "82", "Tarn-et-Garonne"
  it_behaves_like "a result checker", nil, "82 - Tarn-et-Garonne", "82", "Tarn-et-Garonne"
  it_behaves_like "a result checker", '', "82 - Tarn-et-Garonne", "82", "Tarn-et-Garonne"
  it_behaves_like "a result checker", "83", "83 - Var", "83", "Var"
  it_behaves_like "a result checker", nil, "83 - Var", "83", "Var"
  it_behaves_like "a result checker", '', "83 - Var", "83", "Var"
  it_behaves_like "a result checker", "84", "84 - Vaucluse", "84", "Vaucluse"
  it_behaves_like "a result checker", nil, "84 - Vaucluse", "84", "Vaucluse"
  it_behaves_like "a result checker", '', "84 - Vaucluse", "84", "Vaucluse"
  it_behaves_like "a result checker", nil, "85", "85", "Vendée"
  it_behaves_like "a result checker", "85", "85 - Vendée", "85", "Vendée"
  it_behaves_like "a result checker", nil, "85 - Vendée", "85", "Vendée"
  it_behaves_like "a result checker", '', "85 - Vendée", "85", "Vendée"
  it_behaves_like "a result checker", "86", "86 - Vienne", "86", "Vienne"
  it_behaves_like "a result checker", nil, "86 - Vienne", "86", "Vienne"
  it_behaves_like "a result checker", '', "86 - Vienne", "86", "Vienne"
  it_behaves_like "a result checker", "87", "87 - Haute-Vienne", "87", "Haute-Vienne"
  it_behaves_like "a result checker", nil, "87 - Haute-Vienne", "87", "Haute-Vienne"
  it_behaves_like "a result checker", '', "87 - Haute-Vienne", "87", "Haute-Vienne"
  it_behaves_like "a result checker", "88", "88 - Vosges", "88", "Vosges"
  it_behaves_like "a result checker", nil, "88 - Vosges", "88", "Vosges"
  it_behaves_like "a result checker", '', "88 - Vosges", "88", "Vosges"
  it_behaves_like "a result checker", "89", "89 - Yonne", "89", "Yonne"
  it_behaves_like "a result checker", nil, "89 - Yonne", "89", "Yonne"
  it_behaves_like "a result checker", '', "89 - Yonne", "89", "Yonne"
  it_behaves_like "a result checker", "90", "90 - Territoire de Belfort", "90", "Territoire de Belfort"
  it_behaves_like "a result checker", nil, "90 - Territoire de Belfort", "90", "Territoire de Belfort"
  it_behaves_like "a result checker", '', "90 - Territoire de Belfort", "90", "Territoire de Belfort"
  it_behaves_like "a result checker", "91", "91 - Essonne", "91", "Essonne"
  it_behaves_like "a result checker", nil, "91 - Essonne", "91", "Essonne"
  it_behaves_like "a result checker", '', "91 - Essonne", "91", "Essonne"
  it_behaves_like "a result checker", "92", "92 - Hauts-de-Seine", "92", "Hauts-de-Seine"
  it_behaves_like "a result checker", nil, "92 - Hauts-de-Seine", "92", "Hauts-de-Seine"
  it_behaves_like "a result checker", '', "92 - Hauts-de-Seine", "92", "Hauts-de-Seine"
  it_behaves_like "a result checker", "93", "93 - Seine-Saint-Denis", "93", "Seine-Saint-Denis"
  it_behaves_like "a result checker", nil, "93 - Seine-Saint-Denis", "93", "Seine-Saint-Denis"
  it_behaves_like "a result checker", '', "93 - Seine-Saint-Denis", "93", "Seine-Saint-Denis"
  it_behaves_like "a result checker", "94", "94 - Val-de-Marne", "94", "Val-de-Marne"
  it_behaves_like "a result checker", nil, "94 - Val-de-Marne", "94", "Val-de-Marne"
  it_behaves_like "a result checker", '', "94 - Val-de-Marne", "94", "Val-de-Marne"
  it_behaves_like "a result checker", "95", "95 - Val-d’Oise", "95", "Val-d’Oise"
  it_behaves_like "a result checker", '', "95 - Val-d’Oise", "95", "Val-d’Oise"
  it_behaves_like "a result checker", nil, "95 - Val-d’Oise", "95", "Val-d’Oise"
  it_behaves_like "a result checker", "971", "971 - Guadeloupe", "971", "Guadeloupe"
  it_behaves_like "a result checker", nil, "971 - Guadeloupe", "971", "Guadeloupe"
  it_behaves_like "a result checker", '', "971 - Guadeloupe", "971", "Guadeloupe"
  it_behaves_like "a result checker", "972", "972 - Martinique", "972", "Martinique"
  it_behaves_like "a result checker", nil, "972 - Martinique", "972", "Martinique"
  it_behaves_like "a result checker", '', "972 - Martinique", "972", "Martinique"
  it_behaves_like "a result checker", "973", "973 - Guyane", "973", "Guyane"
  it_behaves_like "a result checker", nil, "973 - Guyane", "973", "Guyane"
  it_behaves_like "a result checker", '', "973 - Guyane", "973", "Guyane"
  it_behaves_like "a result checker", "974", "974 - La Réunion", "974", "La Réunion"
  it_behaves_like "a result checker", nil, "974 - La Réunion", "974", "La Réunion"
  it_behaves_like "a result checker", '', "974 - La Réunion", "974", "La Réunion"
  it_behaves_like "a result checker", "976", "976 - Mayotte", "976", "Mayotte"
  it_behaves_like "a result checker", nil, "976 - Mayotte", "976", "Mayotte"
  it_behaves_like "a result checker", '', "976 - Mayotte", "976", "Mayotte"
  it_behaves_like "a result checker", "99", "99 - Etranger", "99", "Etranger"
  it_behaves_like "a result checker", nil, "99 - Etranger", "99", "Etranger"
  it_behaves_like "a result checker", '', "99 - Etranger", "99", "Etranger"
  it_behaves_like "a result checker", '', "99 - Étranger", "99", "Etranger"
  it_behaves_like "a result checker", nil, "99 - Étranger", "99", "Etranger"
end
