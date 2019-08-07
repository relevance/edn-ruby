# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EDN::CharStream do
  it 'reads a stream in order' do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s.current).to eq('a')
    expect(s.advance).to eq('b')
    expect(s.advance).to eq('c')
    expect(s.advance).to eq(:eof)
    expect(s.current).to eq(:eof)
  end

  it 'keeps returning the current until your advance' do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s.current).to eq('a')
    expect(s.advance).to eq('b')
    expect(s.advance).to eq('c')
  end

  it 'knows if the current char is a digit' do
    s = EDN::CharStream.new(io_for('4f'))
    expect(s).to be_digit
    s.advance
    expect(s).not_to be_digit
  end

  it 'knows if the current char is an alpha' do
    s = EDN::CharStream.new(io_for('a9'))
    expect(s).to be_alpha
    s.advance
    expect(s).not_to be_alpha
  end

  it 'knows if the current char is whitespace' do
    s = EDN::CharStream.new(io_for("a b\nc\td,"))
    expect(s).not_to be_ws

    s.advance
    expect(s).to be_ws

    s.advance
    expect(s).not_to be_ws

    s.advance
    expect(s).to be_ws

    s.advance
    expect(s).not_to be_ws

    s.advance
    expect(s).to be_ws

    s.advance
    expect(s).not_to be_ws

    s.advance
    expect(s).to be_ws
  end

  it 'knows if the current char is a newline' do
    s = EDN::CharStream.new(io_for("a\nb\rc"))
    expect(s).not_to be_newline

    s.advance
    expect(s).to be_newline

    s.advance
    expect(s).not_to be_newline

    s.advance
    expect(s).to be_newline

    s.advance
    expect(s).not_to be_newline
  end

  it 'knows if it is at the eof' do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s).not_to be_eof

    s.advance
    expect(s).not_to be_eof

    s.advance
    expect(s).not_to be_eof

    s.advance
    expect(s).to be_eof
  end

  it 'knows how to skip past a char' do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s.skip_past('a')).to eq('a')
    expect(s.current).to eq('b')
  end

  it 'knows how not to skip a char' do
    s = EDN::CharStream.new(io_for('abc'))
    expect(s.skip_past('X')).to be_nil
  end

  it 'knows how skip to the end of a line' do
    s = EDN::CharStream.new(io_for("abc\ndef"))
    s.skip_to_eol
    expect(s.current).to eq("\n")
    expect(s.advance).to eq('d')
  end

  it 'knows how skip whitespace' do
    s = EDN::CharStream.new(io_for("  \n \t,,,,abc"))
    s.skip_ws
    expect(s.current).to eq('a')
  end
end
