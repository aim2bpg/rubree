require 'rails_helper'

RSpec.describe RegularExpression::RailroadDiagramRenderer do
  describe '.sanitize_svg' do
    let(:raw_svg) { '<svg><script>alert("XSS")</script><text>Test</text></svg>' }

    it 'removes script tags and dangerous content' do
      sanitized = described_class.sanitize_svg(raw_svg)
      expect(sanitized).to include('<svg>')
      expect(sanitized).to include('<text>Test</text>')
      expect(sanitized).not_to include('<script>')
    end

    it 'returns html_safe string' do
      sanitized = described_class.sanitize_svg(raw_svg)
      expect(sanitized).to respond_to(:html_safe)
    end

    context 'when svg is empty' do
      it 'returns an empty string safely' do
        sanitized = described_class.sanitize_svg('')
        expect(sanitized).to eq('')
      end
    end

    context 'when svg contains only allowed tags' do
      let(:valid_svg) { '<svg><path d="M10 10"></path></svg>' }

      it 'returns the same SVG' do
        sanitized = described_class.sanitize_svg(valid_svg)
        expect(sanitized).to eq(valid_svg)
      end
    end
  end

  describe '#render' do
    let(:regular_expression) { 'a+b*' }
    let(:options) { { some_option: true } }
    let(:renderer) { described_class.new(regular_expression: regular_expression, options: options) }

    context 'when expression is valid' do
      before do
        allow(RegularExpression::RailroadDiagramGenerator).to receive(:create_svg_from_regex).and_return('<svg><g></g></svg>')
      end

      it 'returns sanitized SVG' do
        sanitized_svg = renderer.render
        expect(sanitized_svg).to include('<svg>')
        expect(sanitized_svg).to include('<g></g>')
      end
    end

    context 'when expression is invalid' do
      let(:invalid_regular_expression) { '[' } # Invalid regex to simulate error
      let(:renderer) { described_class.new(regular_expression: invalid_regular_expression, options: options) }

      it 'sets an error message and returns nil' do
        result = renderer.render
        expect(result).to be_nil
        expect(renderer.error_message).to be_present
      end
    end

    context 'when expression is blank' do
      let(:renderer) { described_class.new(regular_expression: '', options: options) }

      it 'returns nil' do
        result = renderer.render
        expect(result).to be_nil
      end
    end
  end
end
