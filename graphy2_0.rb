require "rbplotly"
require "byebug"
module Graphy_2
    class Dataset
        attr_accessor :in_label
        # line name would be DHRL
=begin
        @directs = {
            "Y-Velocity UU": {
                "x0-line": {
                    DHRL: {
                        x: [1,2,3,4],
                        y: [1,2,3,4]
                    },
                    EXP: {
                        x: [1,2,3,4],
                        y: [1,2,3,4]
                    }
                }
            }
        }
=end

        def initialize(line_name)
            @line_name = line_name
            @data = {} #going to contain title
            @in_label = false
        end
        def data
            @data
        end
        
        def parse(line)
            
            if line.include?("title") #get title
                @title = line[/\"(.*)"/, 1] #yank anything between qoutes
                unless @data[@title]
                    @data[@title] = {}
                end

            elsif line.include?("labels")
                @labels = line[/\"(.*)"/, 2]
            elsif line.include?("label") # new trace on the graph
                @label = line[/\"(.*)"/, 1] # new label
                unless @data[@title][@label]
                    @data[@title][@label] = {}
                end
                @in_label = true
                
            elsif @in_label # !line.include?(")") &&  within the last parenthesis #NOTE LOOK AT THIS
                
                unless @data[@title][@label][@line_name] 
                    @data[@title][@label][@line_name] = {
                            x: [],
                            y: []
                    }
                end
                points = line.split(' ').map(&:to_f)
                unless points[0].nil? || points[1].nil?
                    @data[@title][@label][@line_name][:x].push points[0]
                    @data[@title][@label][@line_name][:y].push points[1]
                end
            elsif line[0] == ')' #if last parenthesis
                @in_label = false
                
            end
        end
    end
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
            Plotly.auth("jthoward17","90d0ohU0cfSMejNkUm0r")
            plot = Plotly::Plot.new
            #traces = Traces.new
            Dir.empty?("./data") ? (puts "\nPlease put graph data in the data folder"; return) : false
            
            ds = Dataset.new("DHRL")
            ls.each do |file|
                
                unless File.directory?("./data/" + file)
                    
                    File.open("./data/" + file).read.each_line do |line|
                        ds.parse line
                        
                    end
                    ds.in_label = false; #NOTE: bad practice
                    
                    ds.data.keys.each do |title| #"Y-lines-UU"
                        
                        data = []
                        layout = {width: 500, height: 500, title: file};
                        ds.data[title].keys.each do |graph| #"x0-line"
                            
                            ds.data[title][graph].keys.each do |label| #"DHRL"
                                
                                data.push({
                                    x: ds.data[title][graph][label][:x], 
                                    y: ds.data[title][graph][label][:y],
                                    type: :scatter,
                                    mode: label,
                                    marker: { 
                                        color: "rgba(#{rand(1..200)}, #{rand(1..200)}, #{rand(1..200)}, 1)"
                                    }
                                })
                                
                            end
                            plot = Plotly::Plot.new(data: data, layout: layout)
                            Dir.exist?("./graphs/#{file}") ? true : Dir.mkdir("./graphs/#{file}")
                            #plot.download_image(path: "./graphs/#{title}/#{ls.index(file)}.png")
                            plot.generate_html(path: "./graphs/#{file}/#{graph}_#{ls.index(file)}.html", open: false)
                        end
                    end
                    #plot.data = traces.data 
                    #plot.layout = traces.layout
                    #
                    #plot = Plotly::Plot.new(data: traces.data, layout: traces.layout).download_image(path: "./graphs/#{traces.title}/#{ls.index(file)}.png")
                    #plot.generate_html(path: "./graphs/#{traces.title}_#{ls.index(file)}.html", open: false)
                    

                end
            end
        end
        def ls
            Dir.entries("./data")
        end
        
    
    end
end
Graphy_2.usage
Graphy_2.read_files