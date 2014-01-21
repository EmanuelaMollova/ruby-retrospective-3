module Graphics
  class Canvas
    attr_reader :width,:height

    def initialize(width, height)
      @width  = width
      @height = height
      @pixels = {}
    end

    def set_pixel(x, y)
      @pixels[[x, y]] = true
    end

    def pixel_at?(x, y)
      @pixels[[x, y]]
    end

    def render_as(renderer)
      renderer.new.render(self)
    end

    def draw(figure)
      figure.draw_on(self)
    end
  end

  class Renderers
    def render(canvas)
      rows = 0.upto(canvas.height - 1).map do |y|
        0.upto(canvas.width - 1).map { |x| draw_pixel(x, y, canvas) }
      end

      rows = rows.map(&:join).join(@end_of_line)
    end

    def draw_pixel(x, y, canvas)
      canvas.pixel_at?(x, y) ? @filled_pixel : @empty_pixel
    end

    class Ascii < Renderers
      def initialize
        @filled_pixel = '@'
        @empty_pixel  = '-'
        @end_of_line  = "\n"
      end
    end

    class Html < Renderers
      def initialize
        @filled_pixel = '<b></b>'
        @empty_pixel  = '<i></i>'
        @end_of_line  = '<br>'
      end

      def render(canvas)
        <<-HEADER + super + <<-FOOTER
          <!DOCTYPE html>
          <html>
          <head>
            <title>Rendered Canvas</title>
            <style type="text/css">
              .canvas {
                font-size: 1px;
                line-height: 1px;
              }
              .canvas * {
                display: inline-block;
                width: 10px;
                height: 10px;
                border-radius: 5px;
              }
              .canvas i {
                background-color: #eee;
              }
              .canvas b {
                background-color: #333;
              }
            </style>
          </head>
          <body>
            <div class="canvas">
        HEADER
            </div>
          </body>
          </html>
        FOOTER
      end
    end
  end

  class Point
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def draw_on(canvas)
      canvas.set_pixel(x, y)
    end

    def ==(other)
      @x == other.x and @y == other.y
    end

    def eql?(other)
      @x.eql? other.x and @y.eql? other.y
    end

    def hash
      [x, y].hash
    end
  end

  module Figure
    def sort_points(*points)
      points.sort_by { |point| [point.x, point.y] }
    end
  end

  class Line
    include Figure

    attr_reader :from, :to

    def initialize(from, to)
      points = sort_points(from, to)
      @from  = points.first
      @to    = points.last
    end

    def draw_on(canvas)
      BresenhamRasterization.new(from, to).draw_line_on(canvas)
    end

    def ==(other)
      @from == other.from and @to == other.to
    end

    def eql?(other)
      @from.eql? other.from and @to.eql? other.to
    end

    def hash
      [from, to].hash
    end

    class BresenhamRasterization
      def initialize(from, to)
        @from_x, @from_y = from.x, from.y
        @to_x, @to_y     = to.x, to.y
        @steep_slope     = (@to_y - @from_y).abs > (@to_x - @from_x).abs
        prepare_values
      end

      def reverse_if_steep_slope
        if @steep_slope
          @from_x, @from_y = @from_y, @from_x
          @to_x, @to_y     = @to_y, @to_x
        end
      end

      def set_from_and_to_coordinates
        if @from_x > @to_x
          @from_x, @to_x = @to_x, @from_x
          @from_y, @to_y = @to_y, @from_x
        end
        @y = @from_y
      end

      def set_delta_and_error
        @delta_x = @to_x - @from_x
        @delta_y = (@to_y - @from_y).abs
        @error   = (@delta_x / 2).to_i
      end

      def set_y_step
        @from_y < @to_y ? @y_step = 1 : @y_step = -1
      end

      def prepare_values
        reverse_if_steep_slope
        set_from_and_to_coordinates
        set_delta_and_error
        set_y_step
      end

      def recalculate_values
          @error -= @delta_y
          if @error < 0
            @y     += @y_step
            @error += @delta_x
          end
      end

      def draw_line_on(canvas)
        @from_x.upto(@to_x).each do |x|
          @steep_slope ? canvas.set_pixel(@y, x) : canvas.set_pixel(x, @y)
          recalculate_values
        end
      end
    end
  end

  class Rectangle
    include Figure
    attr_reader :left, :right

    def initialize(left, right)
      points = sort_points(left, right)
      @left  = points.first
      @right = points.last
    end

    def vertices
      sort_points(
        @left,
        @right,
        Point.new(@left.x, @right.y),
        Point.new(@right.x, @left.y)
      )
    end

    VERTICES = {
      top_left:     0,
      bottom_left:  1,
      top_right:    2,
      bottom_right: 3
    }

    VERTICES.each do |vertex_name, index|
      define_method(vertex_name) { vertices[index] }
    end

    def draw_on(canvas)
      [
        Line.new(bottom_left, bottom_right),
        Line.new(top_right, bottom_right),
        Line.new(top_left, top_right),
        Line.new(top_left, bottom_left)
      ].each { |line| line.draw_on(canvas) }
    end

    def ==(other)
      top_left == other.top_left and bottom_right == other.bottom_right
    end

    def eql?(other)
      top_left.eql? other.top_left and bottom_right.eql? other.bottom_right
    end

    def hash
      [top_left, bottom_right].hash
    end
  end
end
