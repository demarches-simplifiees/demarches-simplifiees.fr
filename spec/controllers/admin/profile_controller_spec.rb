require 'spec_helper'

describe Admin::ProfileController, type: :controller do
  it { expect(described_class).to be < AdminController }
end