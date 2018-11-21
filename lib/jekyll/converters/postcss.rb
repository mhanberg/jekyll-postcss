# frozen_string_literal: true

module Jekyll
  module Converters
    class PostCss < Converter
      safe true
      priority :low

      def matches(ext)
        ext.casecmp(".css").zero?
      end

      def output_ext(_ext)
        ".css"
      end

      def convert(content)
        raise PostCssNotFoundError unless File.file?("./node_modules/.bin/postcss")

        compiled_css, status = Open3.capture2("./node_modules/.bin/postcss", :stdin_data => content)

        raise PostCssRuntimeError unless status.success?

        compiled_css
      end
    end
  end
end

class PostCssNotFoundError < RuntimeError; end
class PostCssRuntimeError < RuntimeError; end
