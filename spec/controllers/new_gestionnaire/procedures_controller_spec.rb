require 'spec_helper'

describe NewGestionnaire::ProceduresController, type: :controller do
  describe "before_action: ensure_ownership!" do
    it "is present" do
      before_actions = NewGestionnaire::ProceduresController
        ._process_action_callbacks
        .find_all{|process_action_callbacks| process_action_callbacks.kind == :before}
        .map(&:filter)

      expect(before_actions).to include(:ensure_ownership!)
    end
  end

  describe "ensure_ownership!" do
    let(:gestionnaire) { create(:gestionnaire) }

    before do
      @controller.params[:procedure_id] = asked_procedure.id
      expect(@controller).to receive(:current_gestionnaire).and_return(gestionnaire)
      allow(@controller).to receive(:redirect_to)

      @controller.send(:ensure_ownership!)
    end

    context "when a gestionnaire asks for its procedure" do
      let(:asked_procedure) { create(:procedure, gestionnaires: [gestionnaire]) }

      it "does not redirects nor flash" do
        expect(@controller).not_to have_received(:redirect_to)
        expect(flash.alert).to eq(nil)
      end
    end

    context "when a gestionnaire asks for another procedure" do
      let(:asked_procedure) { create(:procedure) }

      it "redirects and flash" do
        expect(@controller).to have_received(:redirect_to).with(root_path)
        expect(flash.alert).to eq("Vous n'avez pas accès à cette procédure")
      end
    end
  end
end
