require "stringio"
require "ipaddr"

class RequestBodyLimit
  MAX_BYTES = 64 * 1024

  def initialize(app)
    @app = app
  end

  def call(env)
    trusted = Rails.application.config.action_dispatch.trusted_proxies
    peer = IPAddr.new(env.fetch("REMOTE_ADDR", "0.0.0.0")) rescue nil
    unless peer && trusted.any? { |network| network.include?(peer) }
      %w[HTTP_X_FORWARDED_FOR HTTP_X_REAL_IP HTTP_CLIENT_IP HTTP_FORWARDED HTTP_X_FORWARDED_HOST HTTP_X_FORWARDED_PROTO].each { |header| env.delete(header) }
    end
    return rejected if env["CONTENT_LENGTH"].to_i > MAX_BYTES
    input = env["rack.input"]
    if input && %w[POST PATCH PUT DELETE].include?(env["REQUEST_METHOD"])
      input.rewind if input.respond_to?(:rewind)
      body = input.read(MAX_BYTES + 1).to_s
      return rejected if body.bytesize > MAX_BYTES
      env["rack.input"] = StringIO.new(body)
    end
    @app.call(env)
  end

  private

  def rejected
    [ 413, { "content-type" => "text/plain; charset=utf-8", "cache-control" => "no-store" }, [ "Solicitação muito grande." ] ]
  end
end
