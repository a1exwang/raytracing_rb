def fork_jobs(jobs, parent_work, &child_work)
  threads = []
  pids = []
  is_parent = true
  jobs.times do |i|
    pid = fork
    if pid
      pids << pid
      threads << Thread.new do
        begin
          Process.waitpid(pid)
        rescue Exception => e
          Process.kill(9, pid)
          raise e
        end
      end
    else
      is_parent = false
      child_work.call(i)
    end
  end

  if is_parent
    begin
      threads.each(&:join)
    rescue Exception => e
      pids.each { |pid| Process.kill(9, pid) }
      raise e
    end
    parent_work.call
  end
end
