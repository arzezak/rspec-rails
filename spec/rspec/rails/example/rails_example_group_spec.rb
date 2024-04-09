module RSpec::Rails
  RSpec.describe RailsExampleGroup do
    if ::Rails::VERSION::MAJOR >= 7
      it 'supports tagged_logger' do
        expect(described_class.private_instance_methods).to include(:tagged_logger)
      end
    end

    it 'does not leak context between example groups', if: ::Rails::VERSION::MAJOR >= 7 do
      groups =
        [
          RSpec::Core::ExampleGroup.describe("A group") do
            include RSpec::Rails::RailsExampleGroup
            specify { expect(ActiveSupport::ExecutionContext.to_h).to eq({}) }
          end,
          RSpec::Core::ExampleGroup.describe("A controller group", type: :controller) do
            specify do
              Rails.error.set_context(foo: "bar")
              expect(ActiveSupport::ExecutionContext.to_h).to eq(foo: "bar")
            end
          end,
          RSpec::Core::ExampleGroup.describe("Another group") do
            include RSpec::Rails::RailsExampleGroup
            specify { expect(ActiveSupport::ExecutionContext.to_h).to eq({}) }
          end
        ]

      results =
        groups.map do |group|
          group.run(failure_reporter) ? true : failure_reporter.exceptions
        end

      expect(results).to all be true
    end

    describe 'CurrentAttributes' do
      let(:current_class) do 
        Class.new(ActiveSupport::CurrentAttributes) do
          attribute :request_id
        end
      end

      it 'does not leak current attributes between example groups', if: ::Rails::VERSION::MAJOR >= 7 do
        groups =
          [
            RSpec::Core::ExampleGroup.describe("A group") do
              include RSpec::Rails::RailsExampleGroup
              specify { expect(current_class.attributes).to eq({}) }
            end,
            RSpec::Core::ExampleGroup.describe("A controller group", type: :controller) do
              specify do
                current_class.request_id = "123"
                expect(current_class.attributes).to eq(request_id: "123")
              end
            end,
            RSpec::Core::ExampleGroup.describe("Another group") do
              include RSpec::Rails::RailsExampleGroup
              specify { expect(current_class.attributes).to eq({}) }
            end
          ]
      
        results =
          groups.map do |group|
            group.run(failure_reporter) ? true : failure_reporter.exceptions
          end
      
        expect(results).to all be true
      end
    end
  end
end
