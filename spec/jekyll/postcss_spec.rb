# frozen_string_literal: true

RSpec.describe Jekyll::Converters::PostCss do
  before do
    @converter = Jekyll::Converters::PostCss.new(configuration)
    allow(File).to receive(:file?).with("_includes/syntax.css") { true }
  end
  let(:configuration) do
    Jekyll::Configuration::DEFAULTS
  end

  it "has a version number" do
    expect(Jekyll::PostCss::VERSION).not_to be nil
  end

  it "matches .css files" do
    expect(@converter.matches(".css")).to be true
  end

  it "always outputs the .css file extension" do
    expect(@converter.output_ext(".not-css")).to eql ".css"
  end

  it "raises a PostCssNotFoundError when it PostCSS is not installed" do
    allow(File).to receive(:file?) { false }

    expect { @converter.convert(nil) }.to raise_error PostCssNotFoundError
  end

  it "raises a PostCssRuntimeError if the PostCSS process does not succeed" do
    status = instance_double(Process::Status)

    allow(File).to receive(:file?) { true }
    expect(status).to receive(:success?) { false }
    allow(Open3).to receive(:capture2) { [nil, status] }

    expect { @converter.convert("") }.to raise_error(PostCssRuntimeError)
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

    result = @converter.convert(unconverted_content)

    expect(result).to eq converted_css
  end

  it "won't recompile the css if it hasn't changed" do
    unchanged_css = "unchanged css"
    status = instance_double(Process::Status)

    allow(File).to receive(:file?) { true }
    expect(status).to receive(:success?) { true }
    expect(Open3).to receive(:capture2) { ["cached css", status] }.once

    @converter.convert(unchanged_css)
    result = @converter.convert(unchanged_css)

    expect(result).to eq("cached css")
  end

  it "caches css imports" do
    syntax_css = "abc"
    unconverted_content = <<~CSS
      @import "_includes/syntax";
    CSS
    status = instance_double(Process::Status)

    allow(File).to receive(:file?).with("./node_modules/.bin/postcss") { true }
    expect(File).to receive(:file?).with("_includes/syntax.css") { true }
    expect(IO).to receive(:read).with("_includes/syntax.css") { syntax_css }.twice
    expect(status).to receive(:success?) { true }
    expect(Open3).to receive(:capture2) { ["cached css", status] }.once

    @converter.convert(unconverted_content)
    result = @converter.convert(unconverted_content)

    expect(result).to eq("cached css")
  end

  it "will recompile if imports have changed" do
    syntax_css = "abc"
    unconverted_content = <<~CSS
      @import "_includes/syntax";
    CSS
    status = instance_double(Process::Status)

    allow(File).to receive(:file?).with("./node_modules/.bin/postcss") { true }
    expect(File).to receive(:file?).with("_includes/syntax.css") { true }
    expect(IO).to receive(:read).with("_includes/syntax.css") { syntax_css }.once
    expect(IO).to receive(:read).with("_includes/syntax.css") { "changed" }.once
    expect(status).to receive(:success?) { true }.twice
    expect(Open3).to receive(:capture2) { ["first", status] }.once.ordered
    expect(Open3).to receive(:capture2) { ["second", status] }.once.ordered

    result1 = @converter.convert(unconverted_content)
    result2 = @converter.convert(unconverted_content)

    expect(result1).to eq("first")
    expect(result2).to eq("second")
  end

  it "will ignore imports it can't find" do
    unconverted_content = <<~CSS
      @import "tailwind/base";
    CSS
    status = instance_double(Process::Status)

    allow(File).to receive(:file?).with("./node_modules/.bin/postcss") { true }
    expect(File).to receive(:file?).with("tailwind/base.css") { false }
    expect(status).to receive(:success?) { true }
    expect(Open3).to receive(:capture2) { ["css", status] }.once

    result = @converter.convert(unconverted_content)

    expect(result).to eq("css")
  end
end
