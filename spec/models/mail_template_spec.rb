require 'spec_helper'

describe MailTemplate do
  it { is_expected.to have_db_column(:body) }
  it { is_expected.to have_db_column(:type) }

  it { is_expected.to belong_to(:procedure) }

  describe '.replace_tags' do
    let(:dossier) { create :dossier }
    let(:initiated_mail) { InitiatedMail.default }

    it 'works' do
        initiated_mail.object = '[TPS] --numero_dossier-- --libelle_procedure-- --lien_dossier-- --email-- --nom_organisation--'
        expected =
          "[TPS] 1 Demande de subvention " +
          "<a target=\"_blank\" href=\"http://localhost:3000/users/dossiers/1/recapitulatif\">http://localhost:3000/users/dossiers/1/recapitulatif</a> " +
          "#{dossier.user.email} Orga SGMAP"

        expect(initiated_mail.object_for_dossier(dossier)).to eq(expected)
    end
  end
end
