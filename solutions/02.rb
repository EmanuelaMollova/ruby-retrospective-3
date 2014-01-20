class Task
  attr_reader :status, :description, :priority, :tags

  def initialize(status, description, priority, tags)
    @status      = status
    @description = description
    @priority    = priority
    @tags        = tags
  end
end

class TodoList
  include Enumerable

  attr_reader :tasks

  def initialize(tasks = [])
    @tasks = tasks
  end

  def self.parse(text)
    TodoList.new Parser.new(text).tasks
  end

  def completed?
    @tasks.all? { |task| task.status == :done }
  end

  def tasks_todo
    @tasks.count { |task| task.status == :todo }
  end

  def tasks_in_progress
    @tasks.count { |task| task.status == :current }
  end

  def tasks_completed
    @tasks.count { |task| task.status == :done }
  end

  def filter(criteria)
    TodoList.new @tasks.select { |task| criteria.meets? task }
  end

  def adjoin(todo_list)
    TodoList.new @tasks + todo_list.tasks
  end

  def each
    @tasks.each { |task| yield task }
  end

  class Parser
    attr_reader :tasks

    def initialize(text)
      @tasks = parse_lines text
    end

    def parse_lines(text)
      tasks = text.lines.map { |line| create_from_line(line) }
      TodoList.new tasks
    end

    def create_from_line(line)
      fields = line.split('|').map(&:strip)
      create_from_fields(*fields)
    end

    def create_from_fields(status, description, priority, tags)
      status   = status.downcase.to_sym
      priority = priority.downcase.to_sym
      tags     = tags.split(',').map(&:strip)
      Task.new status, description, priority, tags
    end
  end
end

class Criteria
  def initialize(&condition)
    @condition = condition
  end

  def meets? (task)
    @condition.call task
  end

  class << self
    def status(status)
      Criteria.new { |task| task.status == status }
    end

    def priority(priority)
      Criteria.new { |task| task.priority == priority }
    end

    def tags(tags)
      Criteria.new { |task| (tags & task.tags).size == tags.size }
    end
  end

  def &(other)
    Criteria.new { |task| meets? task and other.meets? task }
  end

  def |(other)
    Criteria.new { |task| meets? task or other.meets? task }
  end

  def !
    Criteria.new { |task| !meets? task }
  end
end
