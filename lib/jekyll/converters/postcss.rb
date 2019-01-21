# frozen_string_literal: true

require "open3"
require "digest"

module Jekyll
  module Converters
    class PostCss < Converter
      safe true
      priority :low

      def initialize(config = {})
        super

        @raw_cache = nil
        @converted_cache = nil
      end

      def matches(ext)
        ext.casecmp(".css").zero?
      end

      def output_ext(_ext)
        ".css"
      end

      def convert(content)
        raise PostCssNotFoundError unless File.file?("./node_modules/.bin/postcss")

        raw_digest = Digest::MD5.hexdigest content
        if @raw_cache != raw_digest
          @raw_cache = raw_digest

          compiled_css, status =
            Open3.capture2("./node_modules/.bin/postcss", :stdin_data => content)

          raise PostCssRuntimeError unless status.success?

          @converted_cache = compiled_css
        else
          @converted_cache
        end
      end
    end
  end
end

class PostCssNotFoundError < RuntimeError; end
class PostCssRuntimeError < RuntimeError; end
