module Asm
  module Operations
    def mov(destination_register, source)
      @registers[destination_register] = find_value(source)
    end

    def inc(destination_register, value = 1)
      @registers[destination_register] += find_value(value)
    end

    def dec(destination_register, value = 1)
      @registers[destination_register] -= find_value(value)
    end

    def cmp(register, value)
      @last_comparison = (@registers[register] <=> find_value(value))
    end

    def find_value(value)
      @registers[value] or value
    end
  end

  module Jumps
    def jmp(where)
      @pc = (@labels[where] or where)
    end

    jumps = {
      je:  :'==',
      jne: :'!=',
      jl:  :'<',
      jle: :'<=',
      jg:  :'>',
      jge: :'>=',
    }

    jumps.each do |jump_name, comparison|
      define_method jump_name do |where|
        @last_comparison.public_send(comparison, 0) ? (return jmp(where)) : @pc = @pc.succ
      end
    end
  end

  class Evaluator
    include Operations
    include Jumps

    class Storage
      attr_reader :labels, :methods_to_call

      def initialize(&block)
        @methods_to_call = []
        @labels          = {}
        instance_eval(&block)
      end

      def method_missing(method_name, *args)
        if (Operations.instance_methods + Jumps.instance_methods).include? method_name
          @methods_to_call << [method_name, args]
        else
          method_name.to_sym
        end
      end

      def label(label_name)
        @labels[label_name] = @methods_to_call.size
      end
    end

    def initialize(&block)
      @registers       = {ax: 0, bx: 0, cx: 0, dx: 0}
      @last_comparison = 0
      @pc              = 0
      storage          = Storage.new(&block)
      @methods_to_call = storage.methods_to_call
      @labels          = storage.labels
    end

    def evaluate
      while @pc < @methods_to_call.size
        method_name = @methods_to_call[@pc].first
        args        = @methods_to_call[@pc].last
        public_send(method_name, *args)
        @pc = @pc.succ if !Jumps.instance_methods.include? method_name
      end
      @registers.values
    end
  end

  def self.asm(&block)
    Evaluator.new(&block).evaluate
  end
end
