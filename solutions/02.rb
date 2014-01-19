class Task
  attr_accessor :status, :description, :priority, :tags

  def initialize(status, description, priority, tags)
    @status      = status
    @description = description
    @priority    = priority
    @tags        = tags
  end

  class << self
    def create_from_fields(fields)
      status   = fields[0].downcase.to_sym
      priority = fields[2].downcase.to_sym
      tags     = fields[3] ? fields[3].split(',').each(&:strip!) : []
      Task.new(status, fields[1], priority, tags)
    end

    def create_from_line(line)
      fields = line.split('|').each(&:strip!)
      create_from_fields(fields)
    end
  end
end

class TodoList
  include Enumerable

  attr_accessor :tasks

  def initialize(tasks)
    @tasks = tasks
  end

  def self.parse(text)
    tasks = text.lines.map { |line| Task.create_from_line(line) }
    TodoList.new(tasks)
  end

  def completed?
    tasks.all? { |task| task.status.equal? :done }
  end

  def tasks_todo
    tasks.select { |task| task.status.equal? :todo }.size
  end

  def tasks_in_progress
    tasks.select { |task| task.status.equal? :current }.size
  end

  def tasks_completed
    tasks.select { |task| task.status.equal? :done }.size
  end

  def filter(criteria)
    TodoList.new(tasks.select(&criteria.block))
  end

  def adjoin(todo_list)
    TodoList.new(tasks + todo_list.tasks)
  end

  def each
    @tasks.each { |task| yield(task) }
  end
end

class Criteria
  attr_accessor :block

  def initialize(&block)
    @block = block
  end

  def Criteria.status(status)
    Criteria.new { |task| task.status.equal? status }
  end

  def Criteria.priority(priority)
    Criteria.new { |task| task.priority.equal? priority }
  end

  def Criteria.tags(tags)
    Criteria.new { |task| (tags & task.tags).size.equal? tags.size }
  end

  def &(other)
    Criteria.new { |task| (self.block).call(task) and (other.block).call(task) }
  end

  def |(other)
    Criteria.new { |task| (self.block).call(task) or (other.block).call(task) }
  end

  def !
    Criteria.new { |task| !(self.block).call(task) }
  end
end
