module Graphics
  class Canvas
    attr_reader :width,:height

    def initialize(width, height)
      @width         = width
      @height        = height
      @pixels        = {}
    end

    def set_pixel(x, y)
      @pixels[[x, y]] = true
    end

    def pixel_at?(x, y)
      @pixels[[x, y]]
    end

    def render
      canvas = Array.new(@width * @height, 0)
      @filled_pixels.each { |pixel| canvas[pixel.last * @width + pixel.first] = 1 }
      canvas.each_slice(@width).to_a.map(&:join).join('2')
    end

    def render_as(renderer)
      rendered = render.gsub(/[012]/, renderer.dictionary)
      if renderer == Graphics::Renderers::Html
        renderer.header + rendered + renderer.footer
      else
        rendered
      end
    end

    def draw(figure)
      figure.pixels.each { |pixel| set_pixel(pixel.x, pixel.y) }
    end
  end

  module Renderers
    class Ascii
      class << self
        def dictionary
          {'0' => '-', '1' => '@', '2' => "\n"}
        end
      end
    end

    class Html
      class << self
        def dictionary
          {'0' => '<i></i>', '1' => '<b></b>', '2' => '<br>'}
        end

        def header
          '<!DOCTYPE html>
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
            <div class="canvas">'
        end

        def footer
          '</div>
           </body>
          </html>'
        end
      end
    end
  end

  class Point
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def pixels
      [self]
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

    def pixels
      ([@from, @to] + rasterize_line).uniq
    end

    def rasterize_line(from = @from, to = @to, points = [])
      point = Point.new(((from.x + to.x)/2.0).ceil, ((from.y + to.y)/2.0).ceil)
      return points.uniq if (point == from or point == to)
      points << point
      rasterize_line(from, point, points) if point != from
      rasterize_line(point, to, points) if point != to
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
  end

  class Rectangle
    include Figure
    attr_reader :left, :right

    def initialize(left, right)
      points = sort_points(left, right)
      @left  = points.first
      @right = points.last
    end

    def vertexes
      sort_points(
        @left,
        @right,
        Point.new(@left.x, @right.y),
        Point.new(@right.x, @left.y)
      )
    end

    def top_left
      vertexes[0]
    end

    def bottom_left
      vertexes[1]
    end

    def top_right
      vertexes[2]
    end

    def bottom_right
      vertexes[3]
    end

    def pixels
      (Line.new(bottom_left, bottom_right).pixels +
       Line.new(top_right, bottom_right).pixels +
       Line.new(top_left, top_right).pixels +
       Line.new(top_left, bottom_left).pixels).uniq
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
