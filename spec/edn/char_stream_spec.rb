require 'spec_helper'

describe EDN::CharStream do
  it "reads a stream in order" do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s.current).to eq('a')
    expect(s.advance).to eq('b')
    expect(s.advance).to eq('c')
    expect(s.advance).to eq(:eof)
    expect(s.current).to eq(:eof)
  end

  it "keeps returning the current until your advance" do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s.current).to eq('a')
    expect(s.current).to eq('a')
    expect(s.advance).to eq('b')
  end

  it "knows if the current char is a digit" do
    s = EDN::CharStream.new(io_for('4f'))
    expect(s.digit?).to be_truthy
    s.advance
    expect(s.digit?).to be_falsey
  end

  it "knows if the current char is an alpha" do
    s = EDN::CharStream.new(io_for('a9'))
    expect(s.alpha?).to be_truthy
    s.advance
    expect(s.alpha?).to be_falsey
  end

  it "knows if the current char is whitespace" do
    s = EDN::CharStream.new(io_for("a b\nc\td,"))
    expect(s.ws?).to be_falsey # a

    s.advance
    expect(s.ws?).to be_truthy # " "

    s.advance
    expect(s.ws?).to be_falsey # b

    s.advance
    expect(s.ws?).to be_truthy # \n

    s.advance
    expect(s.ws?).to be_falsey # c

    s.advance
    expect(s.ws?).to be_truthy # \t

    s.advance
    expect(s.ws?).to be_falsey # d

    s.advance
    expect(s.ws?).to be_truthy # ,
  end

  it "knows if the current char is a newline" do
    s = EDN::CharStream.new(io_for("a\nb\rc"))
    expect(s.newline?).to be_falsey # a

    s.advance
    expect(s.newline?).to be_truthy # \n

    s.advance
    expect(s.newline?).to be_falsey # b

    s.advance
    expect(s.newline?).to be_truthy # \r

    s.advance
    expect(s.newline?).to be_falsey # c
  end

  it "knows if it is at the eof" do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s.eof?).to be_falsey # a
    s.advance
    expect(s.eof?).to be_falsey # b
    s.advance
    expect(s.eof?).to be_falsey # c
    s.advance
    expect(s.eof?).to be_truthy
  end

  it "knows how to skip past a char" do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s.skip_past('a')).to eq('a')
    expect(s.current).to eq('b')
  end

  it "knows how not to skip a char" do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s.skip_past('X')).to be_nil
  end

  it "knows how skip to the end of a line" do
    s = EDN::CharStream.new(io_for("abc\ndef"))
    s.skip_to_eol
    expect(s.current).to eq("\n")
    expect(s.advance).to eq('d')
  end

  it "knows how skip whitespace" do
    s = EDN::CharStream.new(io_for("  \n \t,,,,abc"))
    s.skip_ws
    expect(s.current).to eq('a')
  end
end
