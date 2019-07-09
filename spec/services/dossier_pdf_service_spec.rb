require 'spec_helper'

describe DossierPdfService do
  describe '.build_pdf' do
    let(:procedure) { create(:procedure, :with_all_champs) }
    let(:dossier) { create(:dossier, :with_all_champs, :accepte, :for_individual, procedure: procedure, motivation: 'une grosse grosse motivation') }

    it { expect(DossierPdfService.build_pdf(dossier, 'dossier.pdf')).to be_nil }
  end
end
