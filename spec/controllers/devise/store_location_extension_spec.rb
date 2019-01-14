require 'rails_helper'

RSpec.describe Devise::StoreLocationExtension, type: :controller do
  class TestController < ActionController::Base
    include Devise::Controllers::StoreLocation
    include Devise::StoreLocationExtension
  end

  controller TestController do
  end

  describe "#clear_stored_location_for" do
    context 'when a location has been previously stored' do
      before { subject.store_location_for(:user, dossiers_path) }

      it 'delete the stored location' do
        subject.clear_stored_location_for(:user)
        expect(subject.stored_location_for(:user)).to be nil
      end
    end

    context 'when no location has been stored' do
      it { expect(subject.clear_stored_location_for(:user)).to be nil }
    end
  end
end
