require 'minitest/autorun'
require 'net/http'
require 'pathname'
require_relative '../http_server.rb'

# This test suite neither full nor fine programmed.

class TestHttpServer < MiniTest::Unit::TestCase

  def setup
    Thread.new do
      HttpServer.new
    end
    sleep 1
    @http = Net::HTTP.new('localhost', '8080')
  end

  def test_get_file
    response = @http.request(Net::HTTP::Get.new('/test/test.txt'))
    assert_equal '200', response.code
    assert_equal File.read('test/test.txt'), response.body
  end

  def test_head_file
    response = @http.request(Net::HTTP::Head.new('/test/test.txt'))
    assert_equal '200', response.code
    assert_nil response.body
  end

  def test_get_index_file
    response = @http.request(Net::HTTP::Get.new('/test'))
    assert_equal '200', response.code
    assert_equal File.read('test/index.html'), response.body
  end

  def test_not_found
    response = @http.request(Net::HTTP::Get.new('/test/not_exist.html'))
    assert_equal '404', response.code
  end

  def test_forbidden
    File.new('test/forbidden.html', 'w', 0333).close
    File.chmod 0333, 'test/forbidden.html'
    response = @http.request(Net::HTTP::Get.new('/test/forbidden.html'))
    assert_equal '403', response.code
    File.unlink 'test/forbidden.html'
  end

  def test_post_get_and_delete_file
    # Post a file
    post_request = Net::HTTP::Post.new('/test/posted.html')
    post_request.body = File.read 'test/index.html'
    post_response = @http.request(post_request)
    assert_equal '200', post_response.code
    assert_equal File.read('test/index.html'), File.read('test/posted.html')
    # Get it
    get_request = Net::HTTP::Get.new('/test/posted.html')
    get_response = @http.request(get_request)
    assert_equal '200', get_response.code
    assert_equal get_response.body, File.read('test/posted.html')
    # Delete it
    delete_request = Net::HTTP::Delete.new('/test/posted.html')
    delete_response = @http.request(delete_request)
    assert_equal '200', get_response.code
    refute Pathname('test/posted.html').exist?
  end
end