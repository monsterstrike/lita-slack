module SslVerifierPatch
  def initialize(hostname, ssl_opts)
    @hostname   = hostname
    @ssl_opts   = ssl_opts
    @cert_store = OpenSSL::X509::Store.new

    if dir = @ssl_opts[:root_ca_dir]
      Dir.glob(File.join(dir, "*.pem")).each { |ca_path| @cert_store.add_file(ca_path) }
    else
      @cert_store.set_default_paths
    end
  end
  def ssl_verify_peer(cert_text)
    return true unless should_verify?

    certificate = parse_cert(cert_text)
    return false unless certificate

    # check due to cross chain certificate is expired (e.g. LE - DST Root X3)
    # if not expired, pass to store
    if @cert_store.verify(certificate)
      store_cert(certificate)
      @last_cert = certificate
    end

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
