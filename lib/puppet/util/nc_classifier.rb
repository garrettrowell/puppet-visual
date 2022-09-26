require 'faraday'
require 'faraday_middleware'

class Puppet::Util::Nc_classifier
  def initialize
    classification_server = Puppet.settings['server']
    classification_port   = 4433
    classification_url   = "https://#{classification_server}:#{classification_port}"
    
    @conn = Faraday.new(
      url: classification_url,
      headers: { 'Content-Type' => 'application/json' },
      ssl: {
        client_cert: OpenSSL::X509::Certificate.new(File.read Puppet.settings['hostcert']),
        client_key:  OpenSSL::PKey::RSA.new(File.read Puppet.settings['hostprivkey']),
        ca_file:     Puppet.settings['localcacert'],
      }
    )

#    response = conn.get('/classifier-api/v1/groups')
#    puts JSON.parse(response.body)
  end

  def get(endpoint)
    response = @conn.get(endpoint)
    JSON.parse(response.body)
  end
end
