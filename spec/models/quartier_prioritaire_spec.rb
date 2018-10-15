require 'spec_helper'

describe QuartierPrioritaire do
  it { is_expected.to have_db_column(:code) }
  it { is_expected.to have_db_column(:nom) }
  it { is_expected.to have_db_column(:commune) }
  it { is_expected.to have_db_column(:geometry) }

  it { is_expected.to belong_to(:dossier) }

  describe 'geometry' do
    let(:qp) { create :quartier_prioritaire, geometry: qp_geometry }
    let(:qp_geometry) { File.open('spec/fixtures/files/qp_geometry_value.txt').read }

    subject { qp.geometry }

    it { is_expected.to eq JSON.parse(qp_geometry) }
  end
end
