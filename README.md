http_server.rb
==============

Pure ruby http server implementation for training, self-educating, and fun, of course!

Capabilities
------------

 * Supports `GET`, `HEAD`, `POST` and `DELETE` methods
 * Determines MIME types using built-in OS `file` command
 * Can return `200`, `400`, `403` and `404` error codes
 * No dependencies

Usage
-----

Run file `http_server.rb` with ruby and web server will run on port 8080 with document root in current directory.

Require file `http_server.rb` from your code, and run server with `HttpServer.new(address, port, document_root)`

Testing
-------

Run `rake test` to run the test suite.
