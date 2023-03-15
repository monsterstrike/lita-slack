module SslVerifierPatch
  def ssl_verify_peer(cert_text)
    return true unless should_verify?

    certificate = parse_cert(cert_text)
    return false unless certificate

    # do not verify due to cross chain certificate is expired (e.g. LE - DST Root X3)

    store_cert(certificate)
    @last_cert = certificate

    true
  end

  def identity_verified?
    # verify last cert is valid (e.g. ISRG Root)
    @cert_store.verify(@last_cert) && (@last_cert and OpenSSL::SSL.verify_certificate_identity(@last_cert, @hostname))
  end

  def ssl_handshake_completed
    return unless should_verify?

    unless identity_verified?
      raise Faye::WebSocket::SSLError, "@cert_store.verify(@last_cert) => #{@cert_store.verify(@last_cert)}, OpenSSL::SSL.verify_certificate_identity(@last_cert, @hostname)) => #{OpenSSL::SSL.verify_certificate_identity(@last_cert, @hostname)}, cert => #{@last_cert}"
    end
  end
end

Faye::WebSocket::SslVerifier.prepend(SslVerifierPatch)
