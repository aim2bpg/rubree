require 'rails_helper'

RSpec.describe "RegularExpressionsController" do
  describe 'POST #create' do
    let(:params) do
      {
        regular_expression: {
          regular_expression: 'foo',
          test_string: 'foo',
          options: '',
          substitution_string: substitution
        }
      }
    end

    def build_fake(raise_once: false)
      klass = Class.new do
        include ActiveModel::Model
        attr_accessor :regular_expression, :test_string, :raised

        def model_name
          ActiveModel::Name.new(self.class, nil, 'regular_expression')
        end

        def errors
          @errors ||= ActiveModel::Errors.new(self)
        end

        def diagram_svg
          '<svg/>'
        end

        def diagram_error_message
          nil
        end

        def substitute
          @did = true
        end

        def unready?; false; end
        def valid?; true; end
        def match_success; true; end
        def substitution_result; nil; end
        def ruby_code; nil; end
      end

      inst = klass.new

      if raise_once
        inst.define_singleton_method(:display_captures) do
          unless self.raised
            self.raised = true
            raise StandardError.new('boom-boom')
          end
          []
        end
      else
        inst.define_singleton_method(:display_captures) { [] }
      end

      inst
    end

    context 'when everything is fine and substitution present' do
      let(:substitution) { 'bar' }

      it 'calls substitute and renders index' do
        fake = build_fake

        allow(RegularExpression).to receive(:new).and_return(fake)
        allow(fake).to receive(:substitute)

        post regular_expressions_path, params: params

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('turbo-frame id="regexp"')
        expect(fake).to have_received(:substitute)
      end
    end

    context 'when model raises an error during processing' do
      let(:substitution) { '' }

      it 'adds error and renders index with friendly message' do
        fake = build_fake(raise_once: true)
        allow(RegularExpression).to receive(:new).and_return(fake)

        post regular_expressions_path, params: params

        expect(response).to have_http_status(:ok)
        expect(fake.errors[:base].map(&:to_s)).to include('boom-boom')
      end
    end
  end
end
