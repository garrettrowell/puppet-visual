require 'faraday'
require 'faraday_middleware'

class Puppet::Util::Nc_server
  def initialize(options:)
    server = Puppet.settings['server']
    server_port = 8140
    server_url  = "https://#{server}:#{server_port}"

    @conn = Faraday.new(
      url: server_url,
      headers: {
        'Content-Type'     => 'application/json',
        'X-Authentication' => options[:auth_token]
      },
      ssl: {
        client_cert: OpenSSL::X509::Certificate.new(File.read Puppet.settings['hostcert']),
        client_key:  OpenSSL::PKey::RSA.new(File.read Puppet.settings['hostprivkey']),
        ca_file:     Puppet.settings['localcacert'],
      }
    )
  end

  def get(endpoint, params = nil)
    response = @conn.get(endpoint, params)
    JSON.parse(response.body)
  end
end
