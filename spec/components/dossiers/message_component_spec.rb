RSpec.describe Dossiers::MessageComponent, type: :component do
  let(:component) do
    described_class.new(
      commentaire: commentaire,
      connected_user: connected_user,
      messagerie_seen_at: seen_at,
      show_reply_button: show_reply_button,
      groupe_gestionnaire: groupe_gestionnaire
    )
  end
  let(:seen_at) { commentaire.created_at + 1.hour }

  describe 'for dossier' do
    let(:connected_user) { dossier.user }
    let(:dossier) { create(:dossier, :en_construction) }
    let(:show_reply_button) { true }
    let(:commentaire) { create(:commentaire, dossier: dossier) }
    let(:groupe_gestionnaire) { nil }

    subject { render_inline(component).to_html }

    it { is_expected.to have_button("Répondre") }

    context 'escape <img> tag' do
      before { commentaire.update(body: '<img src="demarches-simplifiees.fr" />Hello') }
      it { is_expected.not_to have_selector('img[src="demarches-simplifiees.fr"]') }
    end

    context 'with a seen_at after commentaire created_at' do
      let(:seen_at) { commentaire.created_at + 1.hour  }

      it { is_expected.not_to have_css(".highlighted") }
    end

    context 'with a seen_at after commentaire created_at' do
      let(:seen_at) { commentaire.created_at - 1.hour  }

      it { is_expected.to have_css(".highlighted") }
    end

    context 'with an instructeur message' do
      let(:instructeur) { create(:instructeur) }
      let(:procedure) { create(:procedure) }
      let(:commentaire) { create(:commentaire, instructeur: instructeur, body: 'Second message') }
      let(:dossier) { create(:dossier, :en_construction, commentaires: [commentaire], procedure: procedure) }

      context 'on a procedure with anonymous instructeurs' do
        before { Flipper.enable(:hide_instructeur_email, procedure) }

        context 'redacts the instructeur email' do
          it { is_expected.to have_text(commentaire.body) }
          it { is_expected.to have_text("Instructeur n° #{instructeur.id}") }
          it { is_expected.not_to have_text(instructeur.email) }
        end
      end

      context 'on a procedure where instructeurs names are not redacted' do
        before { Flipper.disable(:hide_instructeur_email, procedure) }

        context 'redacts the instructeur email but keeps the name' do
          it { is_expected.to have_text(commentaire.body) }
          it { is_expected.to have_text(instructeur.email.split('@').first) }
          it { is_expected.not_to have_text(instructeur.email) }
        end
      end

      describe 'delete message button for instructeur' do
        let(:instructeur) { create(:instructeur) }
        let(:procedure) { create(:procedure) }
        let(:dossier) { create(:dossier, :en_construction, commentaires: [commentaire], procedure: procedure) }
        let(:connected_user) { instructeur }
        let(:form_url) { component.helpers.instructeur_commentaire_path(commentaire.dossier.procedure, commentaire.dossier, commentaire) }

        context 'on a procedure where commentaire had been written by connected instructeur' do
          let(:commentaire) { create(:commentaire, instructeur: instructeur, body: 'Second message') }

          it do
            is_expected.to have_selector("form[action=\"#{form_url}\"]")
            is_expected.to have_button(component.t('.delete_button'))
          end
        end

        context 'on a procedure where commentaire had been written by connected instructeur and discarded' do
          let(:commentaire) { create(:commentaire, instructeur: instructeur, body: 'Second message', discarded_at: 2.days.ago) }

          it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
          it { is_expected.to have_selector(".rich-text", text: component.t('.deleted_body')) }
        end

        context 'on a procedure where commentaire had been written by connected an user' do
          let(:commentaire) { create(:commentaire, email: create(:user).email, body: 'Second message') }

          it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
        end

        context 'on a procedure where commentaire had been written by connected an expert' do
          let(:commentaire) { create(:commentaire, expert: create(:expert), body: 'Second message') }

          it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
        end

        context 'on a procedure where commentaire had been written another instructeur' do
          let(:commentaire) { create(:commentaire, instructeur: create(:instructeur), body: 'Second message') }

          it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
        end

        context 'when commentaire is a correction' do
          let(:commentaire) { create(:commentaire, instructeur:, body: 'Please fix this') }
          before { create(:dossier_correction, commentaire:, dossier:) }

          it { is_expected.to have_button(component.t('.delete_with_correction_button')) }
        end
      end

      describe 'autolink simple urls' do
        let(:commentaire) { create(:commentaire, instructeur: instructeur, body: "rdv sur https://demarches.gouv.fr") }
        it { is_expected.to have_link("https://demarches.gouv.fr", href: "https://demarches.gouv.fr") }
      end
    end

    describe '#commentaire_from_guest?' do
      let!(:guest) { create(:invite, dossier: dossier) }

      subject { component.send(:commentaire_from_guest?) }

      context 'when the commentaire sender is not a guest' do
        let(:commentaire) { create(:commentaire, dossier: dossier, email: "michel@pref.fr") }
        it { is_expected.to be false }
      end

      context 'when the commentaire sender is a guest on this dossier' do
        let(:commentaire) { create(:commentaire, dossier: dossier, email: guest.email) }
        it { is_expected.to be true }
      end
    end

    describe '#commentaire_date' do
      let(:present_date) { Time.zone.local(2018, 9, 2, 10, 5, 0) }
      let(:creation_date) { present_date }
      let(:commentaire) do
        Timecop.freeze(creation_date) { create(:commentaire, email: "michel@pref.fr") }
      end

      subject do
        Timecop.freeze(present_date) { component.send(:commentaire_date) }
      end

      it 'doesn’t include the creation year' do
        expect(subject).to eq 'le 2 septembre à 10 h 05'
      end

      context 'when displaying a commentaire created on a previous year' do
        let(:creation_date) { present_date.prev_year }
        it 'includes the creation year' do
          expect(subject).to eq 'le 2 septembre 2017 à 10 h 05'
        end
      end

      context 'when formatting the first day of the month' do
        let(:present_date) { Time.zone.local(2018, 9, 1, 10, 5, 0) }
        it 'includes the ordinal' do
          expect(subject).to eq 'le 1er septembre à 10 h 05'
        end
      end
    end

    describe '#correction_badge' do
      let(:resolved_at) { nil }

      before do
        create(:dossier_correction, commentaire:, dossier:, resolved_at:)
      end

      it 'returns a badge à corriger' do
        expect(subject).to have_text('à corriger')
      end

      context 'connected as instructeur' do
        let(:connected_user) { create(:instructeur) }

        it 'returns a badge en attente' do
          expect(subject).to have_text('en attente')
        end
      end

      context 'when the correction is resolved' do
        let(:resolved_at) { 1.minute.ago }

        it 'returns a badge corrigé' do
          expect(subject).to have_text("corrigé")
        end
      end
    end
  end

  describe 'groupe_gestionnaire' do
    let(:show_reply_button) { false }
    let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: create(:administrateur)) }
    let(:groupe_gestionnaire) { commentaire.groupe_gestionnaire }
    let(:connected_user) { commentaire.sender }
    subject { render_inline(component).to_html }

    it { is_expected.not_to have_button("Répondre") }

    context 'escape <img> tag' do
      before { commentaire.update(body: '<img src="demarches-simplifiees.fr" />Hello') }
      it { is_expected.not_to have_selector('img[src="demarches-simplifiees.fr"]') }
    end

    context 'with a seen_at after commentaire created_at' do
      let(:seen_at) { commentaire.created_at + 1.hour  }

      it { is_expected.not_to have_css(".highlighted") }
    end

    context 'with a seen_at after commentaire created_at' do
      let(:seen_at) { commentaire.created_at - 1.hour  }

      it { is_expected.to have_css(".highlighted") }
    end

    context 'with an gestionnaire message' do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: create(:administrateur), gestionnaire: gestionnaire, body: 'Second message') }

      it 'should display gestionnaire\'s email' do
        is_expected.to have_text(gestionnaire.email)
      end

      describe 'delete message button for gestionnaire' do
        let(:connected_user) { gestionnaire }
        let(:form_url) { component.helpers.gestionnaire_groupe_gestionnaire_commentaire_path(groupe_gestionnaire, commentaire) }

        context 'when commentaire had been written by connected gestionnaire' do
          it { is_expected.to have_selector("form[action=\"#{form_url}\"]") }
        end

        context 'when commentaire had been written by connected gestionnaire and discarded' do
          let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: create(:administrateur), gestionnaire: gestionnaire, body: 'Second message', discarded_at: 2.days.ago) }

          it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
          it { is_expected.to have_selector(".rich-text", text: component.t('.deleted_body')) }
        end

        context 'on a procedure where commentaire had been written another gestionnaire' do
          let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: create(:administrateur), gestionnaire: create(:gestionnaire), body: 'Second message') }

          it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
        end
      end
    end

    describe '#commentaire_from_guest?' do
      subject { component.send(:commentaire_from_guest?) }

      it { is_expected.to be false }
    end

    describe '#commentaire_date' do
      let(:present_date) { Time.zone.local(2018, 9, 2, 10, 5, 0) }
      let(:creation_date) { present_date }
      let(:commentaire) do
        Timecop.freeze(creation_date) { create(:commentaire_groupe_gestionnaire, sender: create(:administrateur)) }
      end

      subject do
        Timecop.freeze(present_date) { component.send(:commentaire_date) }
      end

      it 'doesn’t include the creation year' do
        expect(subject).to eq 'le 2 septembre à 10 h 05'
      end

      context 'when displaying a commentaire created on a previous year' do
        let(:creation_date) { present_date.prev_year }
        it 'includes the creation year' do
          expect(subject).to eq 'le 2 septembre 2017 à 10 h 05'
        end
      end

      context 'when formatting the first day of the month' do
        let(:present_date) { Time.zone.local(2018, 9, 1, 10, 5, 0) }
        it 'includes the ordinal' do
          expect(subject).to eq 'le 1er septembre à 10 h 05'
        end
      end
    end

    describe '#correction_badge' do
      subject { component.send(:correction_badge) }

      it { is_expected.to eq nil }
    end
  end
end
