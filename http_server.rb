#!/usr/bin/env ruby
# coding: utf-8

# А чем вас SimpleHTTPServer (или даже SimpleCGIServer) из стандартной библиотеки Python не устроил?
# Ну, ладно, в Руби нету, реализуем.

# Возможности:
# Поддержка GET, HEAD, POST, DELETE запросов
# Возвращает 404 если не находит, 403 если не может, 400 если не понимает
# Возвращает 200 если всё хорошо

require 'socket'
require 'pathname'
require 'fileutils'

class HttpServer

  STATUSES = {
    ok:          {code: 200, name: 'OK',          message: 'Successfully done'                                    },
    bad_request: {code: 400, name: 'Bad Request', message: 'You have sent malformed request'                      },
    forbidden:   {code: 403, name: 'Forbidden',   message: 'You have not permission to do this'                   },
    not_found:   {code: 404, name: 'Not Found',   message: 'There is nothing here. Check address for misspelling.'},
  }

  def initialize(host='0.0.0.0', port=8080, root=Dir.pwd)
    STDERR.puts "Starting webserver on #{host}:#{port} with root in #{root}..."
    @server = TCPServer.new(host, port)
    @root   = root
    loop do
      @socket  = @server.accept    # Wait for a client to connect
      request = @socket.gets
      STDERR.puts request
      method, path, http = request.strip.split
      # Need to get headers and body for POST request
      # headers = []
      # while (header = @socket.gets)
      #   break if header.strip.empty?
      #   headers << header
      # end
      # body = ""
      # while (str = @socket.gets)
      #   body += str
      # end
      # STDERR.puts headers
      # STDERR.puts body
      filepath = check_existance(path) 
      if filepath.nil?
        raise_http_error :not_found
      else
        case method
          when 'GET'
            get filepath
          when 'HEAD'
            get filepath, false
          when 'POST'
            post filepath, body
          when 'DELETE'
            delete filepath
          else
            raise_http_error :bad_request
        end
      end
      @socket.close
    end
  end

protected

  def raise_http_error(error_name)
    error = STATUSES[error_name.to_sym]
    @socket.print "HTTP/1.1 #{error[:code]} #{error[:name]}\r\n" +
                 "Content-Type: text/plain\r\n" +
                 "Content-Length: #{error[:message].size}\r\n" +
                 "Connection: close\r\n"
    @socket.print "\r\n"
    @socket.print error[:message]
  end

  def get(filepath, print_body=true)
      body = ''
      begin
        body = File.read filepath
      rescue
        raise_http_error :forbidden
        return
      end
      @socket.print "HTTP/1.1 200 OK\r\n" +
                   "Content-Type: text/plain\r\n" +
                   "#{"Content-Length: #{body.size}\r\n" if print_body}" +
                   "Connection: close\r\n"
      @socket.print "\r\n"
      @socket.print body if print_body
  end

  def check_existance(address)
    p = Pathname("#{@root}/#{address}").cleanpath
    p.exist?? p : nil
  end

  def post(filepath, body)
    begin
      File.write filepath, body
    rescue
      raise_http_error :forbidden
    else
      raise_http_error :ok
    end
  end

  def delete(filepath)
    begin
      FileUtils.rm filepath, force: true
    rescue
      raise_http_error :forbidden
    else
      raise_http_error :ok
    end
  end

end
