require 'spec_helper'

describe MailTemplate do
  it { is_expected.to have_db_column(:body) }
  it { is_expected.to have_db_column(:type) }

  it { is_expected.to belong_to(:procedure) }

  describe '.balises' do
    subject { MailTemplate.balises }

    it { expect(subject.size).to eq 1 }

    describe 'numero_dossier' do
      subject { super().first }

      it { expect(subject.first).to eq 'numero_dossier' }

      describe 'attr and description value' do
        subject { super().second }

        it { expect(subject[:attr]).to eq 'dossier.id' }
        it { expect(subject[:description]).to eq "Permet d'afficher le numéro de dossier de l'utilisateur." }
      end
    end
  end
end
