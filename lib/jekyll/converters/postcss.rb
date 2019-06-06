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
        @import_raw_cache = {}
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

        @raw_digest = Digest::MD5.hexdigest content
        @raw_import_digests = import_digests(content)

        if cache_miss.any?
          @raw_cache = @raw_digest.dup
          @import_raw_cache = @raw_import_digests.dup

          compiled_css, status =
            Open3.capture2("./node_modules/.bin/postcss", :stdin_data => content)

          raise PostCssRuntimeError unless status.success?

          @converted_cache = compiled_css
        end

        reset

        @converted_cache
      end

      private

      def import_digests(content)
        content
          .scan(%r!^@import "(?<file>.*)";$!)
          .flatten
          .each_with_object({}) do |import, acc|
            file = "#{import}.css"
            acc[import] = Digest::MD5.hexdigest IO.read(file) if File.file?(file)
          end
      end

      def cache_miss
        @raw_import_digests
          .map { |import, hash| @import_raw_cache[import] != hash }
          .unshift(@raw_cache != @raw_digest)
      end

      def reset
        @raw_digest = nil
        @raw_import_digest = nil
      end
    end
  end
end

class PostCssNotFoundError < RuntimeError; end
class PostCssRuntimeError < RuntimeError; end
