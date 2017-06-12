require 'spec_helper'

describe API::StatistiquesController, type: :controller do
  describe '#GET dossiers_stats' do
    before do
      get :dossiers_stats
    end

    it { expect(response.status).to eq 200 }
  end
end
