# frozen_string_literal: true

RSpec.describe Jekyll::Converters::PostCss do
  before do
    @socket = instance_double(PostCss::Socket)
    @converter = Jekyll::Converters::PostCss.new({ "socket" => @socket }.merge(configuration))
    allow(File).to receive(:file?).with("_includes/syntax.css") { true }
  end

  let(:configuration) do
    Jekyll::Configuration::DEFAULTS
  end

  it "has a version number" do
    expect(Jekyll::PostCss::VERSION).not_to be nil
  end

  it "matches css and sass files" do
    expect(@converter.matches(".css")).to be true
    expect(@converter.matches(".scss")).to be true
    expect(@converter.matches(".sass")).to be true
  end

  it "output extension is the same as the input extension" do
    expect(@converter.output_ext(".random")).to eql ".random"
  end

  it "raises a PostCssNotFoundError when it PostCSS is not installed" do
    allow(Dir).to receive(:exist?) { false }

    expect { @converter.convert(nil) }.to raise_error PostCssNotFoundError
  end

  it "won't recompile the css if it hasn't changed" do
    unconverted_content = "unchanged css"

    allow(Dir).to receive(:exist?).with("./node_modules/postcss") { true }
    expect(@socket).to receive(:write) { unconverted_content }
    expect(@socket).to receive(:read) { "cached css" }.once

    @converter.convert(unconverted_content)
    result = @converter.convert(unconverted_content)

    expect(result).to eq("cached css")
  end

  it "caches css imports" do
    syntax_css = "abc"
    unconverted_content = <<~CSS
      @import "_includes/syntax";
    CSS

    allow(Dir).to receive(:exist?).with("./node_modules/postcss") { true }
    expect(File).to receive(:file?).with("_includes/syntax.css") { true }
    expect(IO).to receive(:read).with("_includes/syntax.css") { syntax_css }.twice
    expect(@socket).to receive(:write) { unconverted_content }
    expect(@socket).to receive(:read) { "cached css" }.once

    @converter.convert(unconverted_content)
    result = @converter.convert(unconverted_content)

    expect(result).to eq("cached css")
  end

  it "will recompile if imports have changed" do
    syntax_css = "abc"
    unconverted_content = <<~CSS
      @import "_includes/syntax";
    CSS

    allow(Dir).to receive(:exist?).with("./node_modules/postcss") { true }
    expect(File).to receive(:file?).with("_includes/syntax.css") { true }
    expect(IO).to receive(:read).with("_includes/syntax.css") { syntax_css }.once
    expect(IO).to receive(:read).with("_includes/syntax.css") { "changed" }.once
    expect(@socket).to receive(:write) { unconverted_content }.twice
    expect(@socket).to receive(:read) { "first" }.once
    expect(@socket).to receive(:read) { "second" }.once

    result1 = @converter.convert(unconverted_content)
    result2 = @converter.convert(unconverted_content)

    expect(result1).to eq("first")
    expect(result2).to eq("second")
  end

  it "will ignore imports it can't find" do
    unconverted_content = <<~CSS
      @import "tailwind/base";
    CSS

    allow(Dir).to receive(:exist?).with("./node_modules/postcss") { true }
    expect(File).to receive(:file?).with("tailwind/base.css") { false }
    expect(@socket).to receive(:write) { unconverted_content }
    expect(@socket).to receive(:read) { "css" }

    result = @converter.convert(unconverted_content)

    expect(result).to eq("css")
  end
end
