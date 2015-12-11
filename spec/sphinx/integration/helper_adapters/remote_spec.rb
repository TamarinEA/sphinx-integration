require "spec_helper"
require "sphinx/integration/helper"

describe Sphinx::Integration::HelperAdapters::Remote do
  let!(:ssh) { instance_double("Sphinx::Integration::HelperAdapters::SshProxy") }
  let(:adapter) { described_class.new }

  before do
    class_double("Sphinx::Integration::HelperAdapters::SshProxy", new: ssh).as_stubbed_const
  end

  describe "#running?" do
    it do
      expect(ssh).to receive(:execute).with("searchd", /--config/, "--status")
      adapter.running?
    end
  end

  describe "#stop" do
    it do
      expect(ssh).to receive(:execute).with("searchd", /--config/, "--stopwait")
      adapter.stop
    end
  end

  describe "#start" do
    it do
      expect(ssh).to receive(:execute).with("searchd", /--config/)
      adapter.start
    end
  end

  describe "#suspend" do
    it do
      adapter.suspend
      server_status = Sphinx::Integration::ServerStatus.new(ThinkingSphinx::Configuration.instance.address)
      expect(server_status.available?).to be false
    end
  end

  describe "#resume" do
    it do
      adapter.resume
      server_status = Sphinx::Integration::ServerStatus.new(ThinkingSphinx::Configuration.instance.address)
      expect(server_status.available?).to be true
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
    before { stub_sphinx_conf(config_file: "/path/sphinx.conf", searchd_file_path: "/path/data") }

    context "when is online" do
      context "when one host" do
        it do
          expect(ssh).to receive(:execute).with("indexer", "--all", "--config /path/sphinx.conf", "--rotate")
          adapter.index(true)
        end
      end

      context "when many hosts" do
        it do
          expect(ThinkingSphinx::Configuration.instance).to receive(:address).and_return(%w(s1.dev s2.dev))
          expect(ssh).to receive(:within).with("s1.dev").and_yield
          expect(ssh).to receive(:execute).
            with("indexer", "--all", "--config /path/sphinx.conf", "--rotate", "--nohup", exit_status: [0, 2])
          expect(ssh).to receive(:execute).
            with('for NAME in /path/data/*_core.tmp.*; do mv -f "${NAME}" "${NAME/\.tmp\./.new.}"; done')
          server = double("server", opts: {port: 22}, user: "sphinx", host: "s1.dev")
          expect(ssh).to receive(:without).with("s1.dev").and_yield(server)
          expect(ssh).to receive(:execute).with("rsync", any_args)
          expect(ssh).to receive(:execute).with("kill", /SIGHUP/)

          adapter.index(true)
        end
      end
    end

    context "when is offline" do
      context "when one host" do
        it do
          expect(ssh).to receive(:execute).with("indexer", "--all", "--config /path/sphinx.conf")
          adapter.index(false)
        end
      end
    end
  end
end