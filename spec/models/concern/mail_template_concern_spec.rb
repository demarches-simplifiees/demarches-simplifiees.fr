require 'spec_helper'

describe MailTemplateConcern do
  let(:procedure) { create(:procedure)}
  let(:dossier) { create(:dossier, procedure: procedure) }
  let(:dossier2) { create(:dossier, procedure: procedure) }
  let(:initiated_mail) { Mails::InitiatedMail.default_for_procedure(procedure) }

  shared_examples "can replace tokens in template" do
    describe 'with no token to replace' do
      let(:template) { '[TPS] rien à remplacer' }
      it do
        is_expected.to eq("[TPS] rien à remplacer")
      end
    end

    describe 'with one token to replace' do
      let(:template) { '[TPS] Dossier : --numero_dossier--' }
      it do
        is_expected.to eq("[TPS] Dossier : #{dossier.id}")
      end
    end

    describe 'with multiples tokens to replace' do
      let(:template) { '[TPS] --numero_dossier-- --libelle_procedure-- --lien_dossier--' }
      it do
        expected =
          "[TPS] #{dossier.id} #{dossier.procedure.libelle} " +
          "<a target=\"_blank\" href=\"http://localhost:3000/users/dossiers/#{dossier.id}/recapitulatif\">http://localhost:3000/users/dossiers/#{dossier.id}/recapitulatif</a>"

        is_expected.to eq(expected)
      end
    end
  end

  describe '.object_for_dossier' do
    before { initiated_mail.object = template }
    subject { initiated_mail.object_for_dossier(dossier) }

    it_behaves_like "can replace tokens in template"
  end

  describe '.body_for_dossier' do
    before { initiated_mail.body = template }
    subject { initiated_mail.body_for_dossier(dossier) }

    it_behaves_like "can replace tokens in template"
  end

  describe '.replace_tags' do
    it "avoids side effects" do
      subject = "n --numero_dossier--"
      expect(initiated_mail.replace_tags(subject, dossier)).to eq("n #{dossier.id}")
      expect(initiated_mail.replace_tags(subject, dossier2)).to eq("n #{dossier2.id}")
    end
  end
end
