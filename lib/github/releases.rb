class Github::Releases

  def self.latest
    latest_release = Github::API.latest_release
    return nil if latest_release.nil?

    release = Hashie::Mash.new JSON.parse(latest_release)
    release.published_at = release.published_at.to_date.strftime('%d/%m/%Y')
    release
  end
end