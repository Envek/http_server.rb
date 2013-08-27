#!/usr/bin/env ruby
# coding: utf-8

# А чем вас SimpleHTTPServer (или даже SimpleCGIServer) из стандартной библиотеки Python не устроил?
# Ну, ладно, в Руби нету, реализуем.

# Возможности:
# Поддержка GET, HEAD, POST, DELETE запросов
# Возвращает 404 если не находит, 403 если не может, 400 если не понимает
# Возвращает 200 если всё хорошо
# Определяет mime-типы и подставляет index.html для папок

# Зависимости: нет, только stdlib, только хардкор

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
      @socket  = @server.accept # Wait for a client to connect
      request = @socket.gets    # Request string (GET / HTTP/1.1)
      STDERR.puts request
      method, path, http_ver = request.strip.split
      headers = @socket.gets("\r\n\r\n").split("\r\n")
      body_size = headers.select{|h| h.start_with? 'Content-Length'}.last.to_s.split(':')[1].to_i
      body = ''
      if not body_size.zero?
        body = @socket.read(body_size)
      end
      if method.empty? or path.empty? or http_ver.empty? or (method == 'POST' and body.empty?)
        raise_http_error :bad_request
      else  
        filepath = Pathname("#{@root}/#{path}").cleanpath
        if not filepath.exist? and not method == 'POST'
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
      end
      @socket.close
    end
  end

protected

  def raise_http_error(error_name)
    error = STATUSES[error_name.to_sym]
    @socket.print "HTTP/1.1 #{error[:code]} #{error[:name]}\r\n" +
                 "Content-Type: text/plain\r\n" +
                 "Content-Length: #{error[:message].bytesize+2}\r\n" +
                 "Connection: close\r\n"
    @socket.print "\r\n"
    @socket.print "#{error[:message]}\r\n"
  end

  def get(filepath, print_body=true)
      # If directory, check for index.html
      if filepath.directory?
        filepath = filepath.join('index.html')
        return raise_http_error :not_found unless filepath.exist?
      end
      # Read file to memory (very bad idea for very large files)
      body = ''
      begin
        body = File.read filepath
      rescue
        raise_http_error :forbidden
        return
      end
      # Determine mime type (doesn't work in windows)
      mime = begin
        IO.popen(["file", "--brief", "--mime-type", filepath.to_s], in: :close, err: :close).read.chomp
      rescue 
        'text/plain'
      end
      # Send answer to client
      @socket.print "HTTP/1.1 200 OK\r\n" +
                   "Content-Type: #{mime}\r\n" +
                   "#{"Content-Length: #{body.bytesize}\r\n" if print_body}" +
                   "Connection: close\r\n"
      @socket.print "\r\n"
      @socket.print body if print_body
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

if __FILE__ == $0
  HttpServer.new
end