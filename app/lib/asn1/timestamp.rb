class ASN1::Timestamp
  ## Poor man’s rfc3161 timestamp decoding
  # This works, as of 2019-05, for timestamps delivered by the universign POST api.
  # We should properly access the ASN1 contents using the sequence and tags structure.
  # However:
  # * It’s hard to do right.
  # * We currently don’t require it for proper operation; timestamps are never exposed to users.
  # * There’s an ongoing PR https://github.com/ruby/openssl/pull/204 for proper timestamp decoding in the ruby openssl library; let’s use OpenSSL::TS once it exists.

  def self.timestampInfo(asn1timestamp)
    asn1 = OpenSSL::ASN1.decode(asn1timestamp)
    tstInfo = OpenSSL::ASN1.decode(asn1.value[1].value[0].value[2].value[1].value[0].value)
    tstInfo
  end

  def self.signature_time(asn1timestamp)
    tstInfo = timestampInfo(asn1timestamp)
    tstInfo.value[4].value
  end

  def self.signed_digest(asn1timestamp)
    tstInfo = timestampInfo(asn1timestamp)
    tstInfo.value[2].value[1].value.unpack1('H*')
  end
end
