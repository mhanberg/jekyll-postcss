# frozen_string_literal: true

require "socket"
require "json"

module PostCss
  class Socket
    class PostCssRuntimeError; end
    START_SCRIPT = File.expand_path("../../bin/command", __dir__)
    POSTCSS_SCRIPT = File.expand_path("../../bin/postcss", __dir__)

    def initialize
      start_dev_server if development?
    end

    def write(data)
      if development?
        @postcss.puts encode(data)
      else
        @compiled_css = `#{POSTCSS_SCRIPT} '#{encode(data)}'`
      end

      nil
    end

    def read
      if development?
        decode(@postcss.gets.chomp)
      else
        raise "You must call PostCss#write before calling PostCss#read" if @compiled_css.nil?

        decode(@compiled_css)
      end
    end

    private

    def encode(data)
      JSON.dump(:raw_content => data)
    end

    def decode(data)
      JSON.parse(data)["compiled_css"]
    end

    def development?
      @env ||= Jekyll.env

      @env == "development"
    end

    def start_dev_server
      Thread.new do
        system "#{START_SCRIPT} #{POSTCSS_SCRIPT} --development"
      end

      @postcss = nil
      while @postcss.nil?
        begin
          @postcss = TCPSocket.open("localhost", 8124)
        rescue StandardError
          nil # Suppressing exceptions
        end
      end
    end
  end
end
