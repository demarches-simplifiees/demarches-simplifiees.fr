require 'spec_helper'

describe Commentaire do
  it { is_expected.to have_db_column(:email) }
  it { is_expected.to have_db_column(:body) }
  it { is_expected.to have_db_column(:created_at) }
  it { is_expected.to have_db_column(:updated_at) }
  it { is_expected.to belong_to(:dossier) }

  it { is_expected.to belong_to(:piece_justificative) }

  describe 'header' do
    let(:commentaire) { Commentaire.new(created_at: Time.utc(2008, 9, 1, 10, 5, 0)) }

    it { expect(commentaire.header).to eq('Votre accompagnateur, le 01 sept. 2008 12:05') }
  end
end
