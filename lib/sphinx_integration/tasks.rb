namespace :thinking_sphinx do
  def wrap_task(name, &block)
    task = Rake::Task["thinking_sphinx:#{name}"]
    native_actions = task.actions.dup
    task.clear_actions

    task.enhance do
      block.call(Proc.new {
        native_actions.each {|a| a.call(task)}
      })
    end
  end

  wrap_task :stop do |orig_block|
    SphinxIntegration::Helper.stop
  end

  wrap_task :start do |orig_block|
    SphinxIntegration::Helper.start
  end

  wrap_task :running_start do |orig_block|
    SphinxIntegration::Helper.running_start
  end

  wrap_task :index do |orig_block|
    SphinxIntegration::Helper.index
  end

  wrap_task :reindex do |orig_block|
    SphinxIntegration::Helper.reindex
  end

  wrap_task :rebuild do |orig_block|
    SphinxIntegration::Helper.reindex
  end
end