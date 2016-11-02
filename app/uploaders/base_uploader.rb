# encoding: utf-8

class BaseUploader < CarrierWave::Uploader::Base
  def cache_dir
    if Rails.env.production?
      if Features.opensimplif?
        '/tmp/opensimplif-cache'
      else
        '/tmp/tps-cache'
      end
    else
      '/tmp/tps-dev-cache'
    end
  end
end