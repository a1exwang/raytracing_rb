def fork_jobs(jobs, parent_work, &child_work)
  threads = []
  is_parent = true
  jobs.times do |i|
    pid = fork
    if pid
      threads << Thread.new do
        Process.waitpid(pid)
      end
    else
      is_parent = false
      child_work.call(i)
    end
  end

  if is_parent
    threads.each(&:join)
    parent_work.call
  end
end
