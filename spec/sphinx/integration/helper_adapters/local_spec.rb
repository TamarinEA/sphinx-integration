require "spec_helper"
require "sphinx/integration/helper"

describe Sphinx::Integration::HelperAdapters::Local do
  let!(:rye) { class_double("Rye").as_stubbed_const }
  let(:adapter) { described_class.new }

  describe "#stop" do
    it do
      expect(rye).to receive(:shell).with(:searchd, /--config/, "--stopwait")
      adapter.stop
    end
  end

  describe "#start" do
    it do
      expect(rye).to receive(:shell).with(:searchd, /--config/)
      adapter.start
    end
  end

  describe "#remove_indexes" do
    it do
      expect(adapter).to receive(:remove_files).with(%r{db/sphinx/test})
      adapter.remove_indexes
    end
  end

  describe "#remove_binlog" do
    context "when path is empty" do
      it do
        allow(ThinkingSphinx::Configuration.instance.configuration.searchd).to receive(:binlog_path).and_return("")
        expect(adapter).to_not receive(:remove_files)
        adapter.remove_binlog
      end
    end

    context "when path is present" do
      it do
        expect(adapter).to receive(:remove_files).with(%r{db/sphinx/test})
        adapter.remove_binlog
      end
    end
  end

  describe "#index" do
    context "when is online" do
      it do
        expect(rye).to receive(:shell).with(:indexer, /--config/, "--rotate")
        adapter.index(true)
      end
    end

    context "when is offline" do
      it do
        expect(rye).to receive(:shell).with(:indexer, /--config/)
        adapter.index(false)
      end
    end
  end
end