# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require "open3"

RSpec.describe Jekyll::Converters::PostCss do
  let(:configuration) { Jekyll::Configuration::DEFAULTS }
  let(:converter) do
    Jekyll::Converters::PostCss.new(configuration)
  end

  it "has a version number" do
    expect(Jekyll::PostCss::VERSION).not_to be nil
  end

  it "matches .css files" do
    expect(converter.matches(".css")).to be true
  end

  it "always outputs the .css file extension" do
    expect(converter.output_ext(".not-css")).to eql ".css"
  end

  it "raises a PostCssNotFoundError when it PostCSS is not installed" do
    allow(File).to receive(:file?) { false }

    expect { converter.convert(nil) }.to raise_error PostCssNotFoundError
  end

  it "raises a PostCssRuntimeError if the PostCSS process does not succeed" do
    status = instance_double(Process::Status)

    allow(File).to receive(:file?) { true }
    expect(status).to receive(:success?) { false }
    allow(Open3).to receive(:capture2) { [nil, status] }

    expect { converter.convert(nil) }.to raise_error(PostCssRuntimeError)
  end

  it "shells out to PostCSS and returns the compiled css" do
    unconverted_content = "unconverted css"
    converted_css = "converted css"
    status = instance_double(Process::Status)

    allow(File).to receive(:file?) { true }
    expect(status).to receive(:success?) { true }
    expect(Open3).to receive(:capture2).with(
      "./node_modules/.bin/postcss",
      :stdin_data => unconverted_content
    ) { [converted_css, status] }

    result = converter.convert(unconverted_content)

    expect(result).to eq converted_css
  end
end

# rubocop:enable Metrics/BlockLength
