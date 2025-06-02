# frozen_string_literal: true

class ActiveStorage::FakeAttachment < Hashie::Dash
  property :filename
  property :name
  property :file
  property :id
  property :created_at
  property :record_type, default: 'Fake'

  def download
    file.read
  end

  def read(*args)
    file.read(*args)
  end

  def close
    file.close
  end

  def attached?
    true
  end
end
