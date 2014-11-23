require "rendezvous/version"

require "openssl"
require "socket"
require "timeout"
require "uri"

class Rendezvous

  module Errors
    class Error < StandardError; end

    class Authentication < Error; end

    class Connection < Error; end

    class Timeout < Error; end
    class ActivityTimeout < Timeout; end
    class ConnectionTimeout < Timeout; end
  end

  DEFAULT_CHUNK_SIZE = 1048576 # 1 megabyte

  attr_reader :activity_timeout, :connect_timeout, :input, :output, :url

  def self.start(options={})
    rendezvous = self.new(options)
    rendezvous.start
  end

  def initialize(options={})
    @activity_timeout = options[:activity_timeout]
    @connect_timeout  = options[:connect_timeout] || 120
    @input            = options[:input] || $stdin
    @output           = options[:output] || $stdout
    @url              = options[:url]
    @ssl_verify_peer  = options.fetch(:ssl_verify_peer, true)
  end

  def start
    begin
      `stty -icanon -echo` if input.isatty

      if input.is_a?(StringIO)
        input.each(DEFAULT_CHUNK_SIZE) do |chunk|
          socket.write(chunk)
          socket.flush
        end

        ios = [socket]
      else
        ios = [socket, input]
      end

      loop do
        if selected = IO.select(ios, nil, nil, activity_timeout)
          if selected.first.first == input
            socket.write(input.readpartial(DEFAULT_CHUNK_SIZE))
            socket.flush
          else
            output.write(socket.readpartial(DEFAULT_CHUNK_SIZE))
          end
        else
          raise Rendezvous::Errors::ActivityTimeout
        end
      end
    rescue EOFError, Errno::EIO
    rescue Interrupt
      socket.write(3.chr)
      socket.flush
      retry
    rescue SignalException => e
      if Signal.list["QUIT"] == e.signo
        socket.write(28.chr)
        socket.flush
        retry
      end
      raise
    ensure
      `stty icanon echo` if input.isatty
    end
  end

  private

  def socket
    @socket ||= begin
      uri = URI.parse(url)
      host, port, secret = uri.host, uri.port, uri.path[1..-1]

      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.ssl_version = :TLSv1

      if @ssl_verify_peer
        ssl_context.ca_file = File.expand_path("../../data/cacert.pem", __FILE__)
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      else
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      Timeout.timeout(connect_timeout) do
        tcp_socket = TCPSocket.open(host, port)
        ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
        ssl_socket.connect
        ssl_socket.sync_close = true

        ssl_socket.hostname = host # SNI
        ssl_socket.post_connection_check(host) if @ssl_verify_peer

        ssl_socket.puts(secret)
        ssl_socket.readline

        ssl_socket
      end
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET
      raise Rendezvous::Errors::Connection
    rescue OpenSSL::SSL::SSLError
      raise Rendezvous::Errors::Authentication
    rescue Timeout::Error
      raise Rendezvous::Errors::ConnectionTimeout
    end
  end

end
