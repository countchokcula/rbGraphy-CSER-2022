require "rbplotly"
class Traces
    def initialize
        
        
        @x = Array.new
        @y = Array.new
        @data = Array.new
    end
    def title
        @title
    end
=begin
    def read_files
        @ls.each do |file|
            unless File.directory?("./data/" + file)
                File.open("./data/" + file).read.each_line do |line|
                    parse line
                end
            end
        end
        
    end
=end
    def push_data
        @data.push({x: @x, y: @y, type: :scatter, mode: :markers, name: @label, marker: { color: "rgba(#{rand(1..200)}, #{rand(1..200)}, #{rand(1..200)}, 1)"} }) # push the new trace
    end
    def parse(line)
        if line.include?("title") #get title
            @title = line[/\"(.*)"/, 1] #yank anything between qoutes
        elsif line.include?("labels")
            @labels = line[/\"(.*)"/, 2]

        elsif line.include?("label") # new trace on the graph

            @label = line[/\"(.*)"/, 1] # new label

            
            @x = []
            @y = []

        elsif !line.include?(")") #within the last parenthesis #NOTE LOOK AT THIS
            points = line.split(' ').map(&:to_f)
            
            unless points[0].nil? || points[1].nil?
                @x.push points[0]
                @y.push points[1]
            end

        elsif line[0] == ')' #if last parenthesis
            push_data
        end
    end
    def data; @data; end
    def layout; {width: 500, height: 500, title: @title}; end
    def print_data
        data.each do |line|
            puts line
        end
    end

end
module Graph
    def self.read_files
        ls.each do |file|
            

            unless File.directory?("./data/" + file)
                @traces=Traces.new
                
                File.open("./data/" + file).read.each_line do |line|
                    @traces.parse line
                end
                Plotly::Plot.new(data: @traces.data, layout: @traces.layout).generate_html(path: "./#{@traces.title}.html", open: false)

            end
              
        end
    end
    def self.ls
        Dir.entries("./data")
    end
end
Graph.read_files