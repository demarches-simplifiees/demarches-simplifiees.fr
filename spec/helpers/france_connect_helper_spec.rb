describe FranceConnectHelper, type: :helper do
  describe ".france_connect_enabled?" do
    subject { france_connect_enabled?(procedure: procedure) }

    context "when FranceConnect service is disabled" do
      before do
        @fc_enabled = Rails.configuration.x.france_connect.enabled
        Rails.configuration.x.france_connect.enabled = false
      end

      after do
        Rails.configuration.x.france_connect.enabled = @fc_enabled
      end

      let(:procedure) { nil }

      it { expect(subject).to eq(false) }
    end

    context "when FranceConnect service is enabled" do
      before do
        @fc_enabled = Rails.configuration.x.france_connect.enabled
        Rails.configuration.x.france_connect.enabled = true
      end

      after do
        Rails.configuration.x.france_connect.enabled = @fc_enabled
      end

      context "and no given procedure" do
        let(:procedure) { nil }

        context "nor an instance wide FranceConnect token" do
          before do
            @fc_token = Rails.application.secrets.france_connect_particulier
            Rails.application.secrets.france_connect_particulier = nil
          end

          after do
            Rails.application.secrets.france_connect_particulier = @fc_token
          end

          it { expect(subject).to eq(false) }
        end

        context "but an instance wide FranceConnect token" do
          before do
            @fc_token = Rails.application.secrets.france_connect_particulier
            Rails.application.secrets.france_connect_particulier = "A_VALID_TOKEN"
          end

          after do
            Rails.application.secrets.france_connect_particulier = @fc_token
          end

          it { expect(subject).to eq(true) }
        end
      end

      context "and given procedure has no FranceConnect token" do
        before do
          allow(procedure).to receive(:fc_particulier_validated?).and_return(false)
        end

        let(:procedure) { build(:procedure) }

        context "and instance wide FranceConnect token is not set" do
          before do
            @fc_token = Rails.application.secrets.france_connect_particulier
            Rails.application.secrets.france_connect_particulier = nil
          end

          after do
            Rails.application.secrets.france_connect_particulier = @fc_token
          end

          it { expect(subject).to eq(false) }
        end

        context "and instance wide FranceConnect token is set" do
          before do
            @fc_token = Rails.application.secrets.france_connect_particulier
            Rails.application.secrets.france_connect_particulier = "A_VALID_TOKEN"
          end

          after do
            Rails.application.secrets.france_connect_particulier = @fc_token
          end

          it { expect(subject).to eq(true) }
        end
      end

      context "and given procedure has a FranceConnect token" do
        before do
          allow(procedure).to receive(:fc_particulier_validated?).and_return(true)
        end

        let(:procedure) { build(:procedure) }

        it { expect(subject).to eq(true) }
      end
    end
  end
end
