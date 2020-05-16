# frozen_string_literal: true

require "socket"
require "json"

module PostCss
  class Socket
    START_SCRIPT = File.expand_path("../../bin/command", __dir__)
    POSTCSS_SCRIPT = File.expand_path("../../bin/postcss", __dir__)

    def initialize
      Thread.new do
        system "#{START_SCRIPT} #{POSTCSS_SCRIPT}"
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

    def write(data)
      @postcss.puts JSON.dump(:raw_content => data)
    end

    def read
      JSON.parse(@postcss.gets.chomp)["compiled_css"]
    end
  end
end
