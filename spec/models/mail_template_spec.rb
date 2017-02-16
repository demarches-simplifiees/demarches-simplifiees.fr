require 'spec_helper'

describe MailTemplate do
  it { is_expected.to have_db_column(:body) }
  it { is_expected.to have_db_column(:type) }

  it { is_expected.to belong_to(:procedure) }

  describe '.tags' do
    subject { MailTemplate::TAGS }

    it { expect(subject.size).to eq 3 }

    describe 'numero_dossier' do
      subject { super()[:numero_dossier] }

      describe 'attr and description value' do

        it { expect(subject[:description]).to eq "Permet d'afficher le numéro de dossier de l'utilisateur." }
      end
    end

    describe 'libelle_procedure' do
      subject { super()[:libelle_procedure] }

      describe 'attr and description value' do

        it { expect(subject[:description]).to eq "Permet d'afficher le libellé de la procédure." }
      end
    end

    describe 'lien_dossier' do
      subject { super()[:lien_dossier] }

      describe 'attr and description value' do

        it { expect(subject[:description]).to eq "Permet d'afficher un lien vers le dossier de l'utilisateur." }
      end
    end
  end

  xdescribe '.replace_tags' do
    let(:dossier) { create :dossier }
    let(:procedure) { dossier.procedure }
    let(:mail_received) { procedure.mail_received }

    describe 'for tag --numero_dossier--' do
      before do
        procedure.mail_received.update_column(:object, '[TPS] Dossier n°--numero_dossier--')
      end

      subject { procedure.mail_received.object_for_dossier dossier }

      it { expect(subject).to eq "[TPS] Dossier n°#{dossier.id}" }
    end

    describe 'for tag --libelle_procedure--' do
      before do
        procedure.mail_received.update_column(:object, '[TPS] Dossier pour la procédure --libelle_procedure--')
      end

      subject { procedure.mail_received.object_for_dossier dossier }

      it { expect(subject).to eq "[TPS] Dossier pour la procédure #{procedure.libelle}" }
    end

    describe 'for tag --lien_dossier--' do
      include Rails.application.routes.url_helpers
      include ActionView::Helpers::UrlHelper

      before do
        procedure.mail_received.update_column(:body, 'Consultez votre dossier ici --lien_dossier--')
      end

      subject { procedure.mail_received.body_for_dossier dossier }

      it { is_expected.to eq "Consultez votre dossier ici #{link_to users_dossier_recapitulatif_url(dossier), users_dossier_recapitulatif_url(dossier), target: '_blank'}" }
    end

    describe 'multiple tags' do
      before do
        procedure.mail_received.update_column(:object, '[TPS] Dossier n°--numero_dossier-- pour la procédure --libelle_procedure-- et encore le numéro : --numero_dossier--')
      end

      subject { procedure.mail_received.object_for_dossier dossier }

      it { expect(subject).to eq "[TPS] Dossier n°#{dossier.id} pour la procédure #{procedure.libelle} et encore le numéro : #{dossier.id}" }
    end
  end
end
