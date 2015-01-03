require 'vcr'
require 'cgi'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!

  # Removes all private data (Basic Auth, Set-Cookie headers...)
  c.before_record do |i|
    i.response.headers.delete('Set-Cookie')
    i.request.headers.delete('Authorization')
    u = URI.parse(i.request.uri)
    i.request.uri.sub!(/:\/\/.*#{Regexp.escape(u.host)}/, "://#{u.host}" )
  end

  username = ENV["HKTV_USER_NAME"] ? ENV["HKTV_USER_NAME"] : "<username>"
  password = ENV["HKTV_PASSWORD"] ? ENV["HKTV_PASSWORD"] : "<password>"

  c.filter_sensitive_data('<HKTV_PASSWORD>') do
    CGI.escape password
  end

  c.filter_sensitive_data('<HKTV_USER_NAME>') do
    CGI.escape username
  end

  # Matches authenticated requests regardless of their Basic auth string (https://user:pass@domain.tld)
  c.register_request_matcher :anonymized_uri do |request_1, request_2|
    (URI(request_1.uri).port == URI(request_2.uri).port) &&
      URI(request_1.uri).path == URI(request_2.uri).path
  end
end