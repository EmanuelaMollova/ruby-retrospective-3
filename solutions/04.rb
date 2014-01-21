module Asm
  module RegisterActions
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
      @next_instruction = (@labels[where] or where) - 1
    end

    JUMPS = {
      je:  :'==',
      jne: :'!=',
      jl:  :'<',
      jle: :'<=',
      jg:  :'>',
      jge: :'>=',
    }

    JUMPS.each do |jump_name, comparison|
      define_method jump_name do |where|
        return jmp(where) if @last_comparison.public_send(comparison, 0)
      end
    end
  end

  class Compiler
    include RegisterActions
    include Jumps

    class Parser
      attr_reader :labels, :methods_to_call

      def initialize(&block)
        @methods_to_call = []
        @labels          = {}
        instance_eval(&block)
      end

      def method_missing(method_name, *args)
        if (RegisterActions.instance_methods + Jumps.instance_methods).include? method_name
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
      @registers        = {ax: 0, bx: 0, cx: 0, dx: 0}
      @last_comparison  = 0
      @next_instruction = 0
      parsed            = Parser.new(&block)
      @methods_to_call  = storage.methods_to_call
      @labels           = storage.labels
    end

    def run
      while @next_instruction < @methods_to_call.size
        public_send *@methods_to_call[@next_instruction]
        @next_instruction = @next_instruction + 1 if !Jumps.instance_methods.include? method_name
      end
      @registers.values
    end
  end

  def self.asm(&block)
    Compiler.new(&block).run
  end
end
