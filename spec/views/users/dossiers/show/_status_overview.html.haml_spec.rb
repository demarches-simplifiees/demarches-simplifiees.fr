describe 'users/dossiers/show/_status_overview.html.haml', type: :view do
  before { allow(dossier.procedure).to receive(:usual_traitement_time_for_recent_dossiers).and_return(1.day) }

  subject! { render 'users/dossiers/show/status_overview.html.haml', dossier: dossier }

  matcher :have_timeline_item do |selector|
    match do |rendered|
      expect(rendered).to have_selector(item_selector(selector))
    end

    chain :active do
      @active = true
    end

    chain :inactive do
      @active = false
    end

    def item_selector(selector)
      item_selector = ".status-timeline #{selector}"
      item_selector += '.active' if @active == true
      item_selector += ':not(.active)' if @active == false
      item_selector
    end
  end

  context 'when en construction' do
    let(:dossier) { create :dossier, :en_construction }

    it 'renders the timeline (without the final states)' do
      expect(rendered).not_to have_timeline_item('.brouillon')
      expect(rendered).to have_timeline_item('.en-construction').active
      expect(rendered).to have_timeline_item('.en-instruction').inactive
      expect(rendered).to have_timeline_item('.termine').inactive
    end

    it { is_expected.to have_selector('.status-explanation .en-construction') }
    it { is_expected.to have_text('Habituellement, les dossiers de cette démarche sont traités dans un délai de 1 jour') }
  end

  context 'when en instruction' do
    let(:dossier) { create :dossier, :en_instruction }

    it 'renders the timeline (without the final states)' do
      expect(rendered).not_to have_timeline_item('.brouillon')
      expect(rendered).to have_timeline_item('.en-construction').inactive
      expect(rendered).to have_timeline_item('.en-instruction').active
      expect(rendered).to have_timeline_item('.termine').inactive
    end

    it { is_expected.to have_selector('.status-explanation .en-instruction') }
    it { is_expected.to have_text('Habituellement, les dossiers de cette démarche sont traités dans un délai de 1 jour') }
  end

  context 'when accepté' do
    let(:dossier) { create :dossier, :accepte, :with_motivation }

    it { is_expected.not_to have_selector('.status-timeline') }
    it { is_expected.to have_selector('.status-explanation .accepte') }
    it { is_expected.to have_text(dossier.motivation) }

    context 'with attestation' do
      let(:dossier) { create :dossier, :accepte, :with_attestation }
      it { is_expected.to have_link(nil, href: attestation_dossier_path(dossier)) }
    end
  end

  context 'when refusé' do
    let(:dossier) { create :dossier, :refuse, :with_motivation }

    it { is_expected.not_to have_selector('.status-timeline') }
    it { is_expected.to have_selector('.status-explanation .refuse') }
    it { is_expected.to have_text(dossier.motivation) }
    it { is_expected.to have_link(nil, href: messagerie_dossier_url(dossier, anchor: 'new_commentaire')) }
  end

  context 'when classé sans suite' do
    let(:dossier) { create :dossier, :sans_suite, :with_motivation }

    it { is_expected.not_to have_selector('.status-timeline') }
    it { is_expected.to have_selector('.status-explanation .sans-suite') }
    it { is_expected.to have_text(dossier.motivation) }
  end
end
