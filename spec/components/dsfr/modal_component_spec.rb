RSpec.describe Dsfr::ModalComponent, type: :component do
  let(:modal_id) { "ModalID" }
  let(:trigger_label) { "TriggerLabel" }
  let(:modal_title) { "ModalTitle" }
  context "without any custom embeded content" do
    context "with trigger object as a button" do
      subject { render_inline(Dsfr::ModalComponent.new(modal_id, modal_title, trigger_label)) }
      it "renders a button that opens the modal" do
        expect(subject).to have_button(trigger_label)
      end

      it "modal has exit button" do
        expect(subject).to have_button("Fermer")
      end

      it "modal has title" do
        expect(subject).to have_text(modal_title)
      end
    end

    context "with trigger object as a link" do
      subject { render_inline(Dsfr::ModalComponent.new(modal_id, modal_title, trigger_label, trigger_using_link: true)) }
      it "renders a link that opens the modal" do
        expect(subject).to have_link(trigger_label, href: "#modal-#{modal_id}")
      end

      it "modal has exit button" do
        expect(subject).to have_button("Fermer")
      end

      it "modal has title" do
        expect(subject).to have_text(modal_title)
      end
    end
  end

  context "with custom embeded content" do
    subject { render_inline(Dsfr::ModalComponent.new(modal_id, modal_title, trigger_label)) { |mod| mod.with_body { "<p>custom content</p>" } } }
    it "renders modal with custom content" do
      expect(subject).to have_text("custom content")
    end
  end
end
