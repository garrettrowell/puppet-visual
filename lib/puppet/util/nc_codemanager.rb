require 'faraday'
require 'faraday_middleware'

class Puppet::Util::Nc_codemanager
  def initialize(options:)
    server = Puppet.settings['server']
    code_manager_port = 8170
    code_manager_url  = "https://#{server}:#{code_manager_port}"

    @conn = Faraday.new(
      url: code_manager_url,
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

  def get(endpoint)
    response = @conn.get(endpoint)
    JSON.parse(response.body)
  end
end
