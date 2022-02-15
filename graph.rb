require "rbplotly"
require "byebug"
class Traces
    def initialize
        
        
        @x = Array.new
        @y = Array.new
        @data = Array.new
    end
    def title
        @title
    end

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

            empty

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
    def empty
        @x = []
        @y = []
        
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
    class << self
        def usage
            puts "WHAT IS: This program takes graph data from the data folder and creates html scatterplot graphs"
        end
        def check_dir
            ["data", "graphs"].each do |dir|
                Dir.exist?(dir) ? true : (Dir.mkdir(dir); puts "Created #{dir} folder")
            end
        end

        def read_files
            check_dir
            #plot = Plotly::Plot.new
            #traces = Traces.new
            Dir.empty?("./data") ? (puts "\nPlease put graph data in the data folder"; return) : false
            ls.each do |file|
                
                unless File.directory?("./data/" + file)
                    traces = Traces.new
                    File.open("./data/" + file).read.each_line do |line|
                        traces.parse line
                    end
                    
                    #plot.data = traces.data 
                    #plot.layout = traces.layout
                    Dir.exist?("./graphs/#{traces.title}") ? true : Dir.mkdir("./graphs/#{traces.title}")
                    plot = Plotly::Plot.new(data: traces.data, layout: traces.layout).generate_html(path: "./graphs/#{traces.title}/#{ls.index(file)}.html", open: false)
                    #plot.generate_html(path: "./graphs/#{traces.title}_#{ls.index(file)}.html", open: false)
                    

                end
            end
        end
        def ls
            Dir.entries("./data")
        end
    end
end
Graph.usage
Graph.read_files