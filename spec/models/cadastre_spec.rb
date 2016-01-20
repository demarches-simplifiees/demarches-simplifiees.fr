require 'spec_helper'

describe Cadastre do
  it { is_expected.to have_db_column(:surface_intersection) }
  it { is_expected.to have_db_column(:surface_parcelle) }
  it { is_expected.to have_db_column(:numero) }
  it { is_expected.to have_db_column(:feuille) }
  it { is_expected.to have_db_column(:section) }
  it { is_expected.to have_db_column(:code_dep) }
  it { is_expected.to have_db_column(:nom_com) }
  it { is_expected.to have_db_column(:code_com) }
  it { is_expected.to have_db_column(:code_arr) }
  it { is_expected.to have_db_column(:geometry) }

  it { is_expected.to belong_to(:dossier) }
end
