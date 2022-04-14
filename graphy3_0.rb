require "rbplotly"
require "byebug"
require "roo"

module Graphy3

    class Xcel
=begin


 

First file: Y(mm), V at X=0, V at X=1, U at X=0, U at X=1,  uu at X=0, uu at X=1, uv at X=0, uv at X=1, vv at X=0, vv at X=1        

Second file: X(mm), (V(y/L=1),U(y/L=1),uu(y/L=1),uv(y/L=1),vv(y/L=1)....V(y/L=8),U(y/L=8),uu(y/L=8),uv(y/L=8),vv(y/L=8))
=end        

        attr_reader :headers, :data
        def headers
            {
                y: ["V0", "V1", "U0", "U1", "uu0", "uu1", "uv0", "uv1", "vv0", "vv1"],
                x: ["V", "U","uu","uv","vv"]
            }
        end
        def initialize(path='./exp.xlsx', headers=[])
            #@headers = headers
            @file = Roo::Spreadsheet.open(path)
            @y_vals = @file.sheet(1)
            @x_vals = @file.sheet(0)

            
            @x_lines = {

            }
            @y_lines = {

            }
            
        end
        def create_data
            headers[:x].each do |head|
                @y_lines[head] = {}
            end
            
            

=begin
            Intended Output:
            @y_lines = {
                "y0-line": {
                    x: [],
                    y: []
                },
                "y1-line": {
                    x: [],
                    y: []
                }
            }

            @x_lines...same thing but with x0-line
=end
            i  = 1
            while i < (@y_vals.last_column) #NOTE: Check this if graphs are wrong
                name = headers[:x][i % 5]
                y = i
                if y % 9 == 0
                    y += 1
                end
                @y_lines[name]["y#{(y % 9)}-line"] = {
                    x: @x_vals.column(headers[:x].index(name)+1), #index could be zero, columns start a 1
                    y: @y_vals.column(i)
                }
                
                i += 1
            end
            
            
            headers[:y].each do |head|
                name = head[/[^\(\)0-9]*/] #removes numbers
                
                unless @x_lines[name]
                    @x_lines[name] = {}
                end
                
                @x_lines[name]["x#{head[/\d+/]}-line"] = { #extract the number x0-line, x1-line
                        x: @x_vals.column(headers[:x].index(name)+1),
                        y: @y_vals.column(headers[:y].index(head)+1)
                }
                    
            end
            
            return {
                x_lines: @x_lines,
                y_lines: @y_lines
            }
        end
    end    
    class Data
        attr_accessor :in_label
=begin
        @data = {
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

        NEW
        @data = {
            DHRL: {
                Y-VEL UU: {
                    x0-line: {
                        x: [1,2,3,4],
                        y: [1,2,3,4]
                    }
                    
                }
            }
        }
=end
        def initialize
            @data = {}
            @markers = {}
        end
        def add_to_hash(xcel)

        end

        def new_set(set_name, titles=[])
            
            @data[set_name] = {}
            titles.each do |t|
                @data[set_name][t] = {}
            end
        end
        def parse_line(name, file, line)

            if line.include?("title") #get title
=begin
                @title = line[/\"(.*)"/, 1] #yank anything between qoutes
                unless @data[@title]
                    @data[@title] = {}
                end
=end
            elsif line.include?("labels")
                #@labels = line[/\"(.*)"/, 2]
            elsif line.include?("label") # new trace on the graph
                @label = line[/\"(.*)"/, 1] # new label
                
                unless @data[name][file][@label]
                    @data[name][file][@label] = {
                        x: [],
                        y: []
                    }
                end
                @in_label = true
                
            elsif @in_label && !(line[0] == ')') # !line.include?(")") &&  within the last parenthesis #NOTE LOOK AT THIS
                
                points = line.split(' ').map(&:to_f)
                unless points[0].nil? || points[1].nil?
                    @data[name][file][@label][:x].push points[0]
                    @data[name][file][@label][:y].push points[1]
                end
                
            elsif line[0] == ")" #if last parenthesis
                
                unless @markers[@label]
                   @markers[name] = { 
                        color: "rgba(#{rand(1..200)}, #{rand(1..200)}, #{rand(1..200)}, 1)"
                    }
                end
                @in_label = false
                
            end
        end
=begin
        @markers = {
            DHRL: {
                color: "rgba(100,100,100,1)"
            }
        }
=end
        def markers # keeps track of colors
            @markers
        end

        def data
            @data
        end
    end

    class << self
        def create_json
            
            File.write("./parsed_data.json", read_files(true).to_json)
            puts "\nCreated parsed_data.json File!"

            File.write("./experimental_data.json", Xcel.new.create_data.to_json)
            puts "\nCreated experimental_data.json File!"

        end
        def ls
            Dir.entries("./data")
        end
        def check_dir
            ["data", "graphs"].each do |dir|
                Dir.exist?(dir) ? true : (Dir.mkdir(dir); puts "\nCreated #{dir} folder")
            end
        end
        def data_set_names
            Dir.entries("./data/").delete_if { |e| e == "." || e == ".." }
        end

        def get_data_file_names
            data_set_names.map { |n| #DHRL DHRL66 ... ect
                Dir.entries("./data/" + n).delete_if {|e| 
                    e == "." || e == ".."
                }
            }.first #prints another array for some reason?
        end

        def get_titles(set)
            Dir.entries("./data/#{set}").delete_if {|e| 
                    e == "." || e == ".."
            }.map { |f| 
                f.delete_suffix(".txt").delete_prefix("data-lines-") 
            }
        end
        
       
        def read_files(json=false)
            check_dir
            #Plotly.auth("jthoward17","90d0ohU0cfSMejNkUm0r")
            plot = Plotly::Plot.new
            
            Dir.empty?("./data") ? (puts "\nPlease put graph data in the data folder"; return) : false
            
            xcel_data = Xcel.new.create_data

            ds = Data.new
            data_set_names.each do |name| #DHRL DHRL66 ... ect
                
                ds.new_set(name, get_titles(name))
                
                Dir.entries("./data/#{name}").each do |f|
                    data_file = "./data/#{name}/#{f}"

                    unless File.directory?(data_file)
                        File.open(data_file).read.each_line do |line|
                            file = f.delete_suffix(".txt").delete_prefix("data-lines-")
                            ds.parse_line(name, file, line)
                            
                        end
                        
                    end
                    
                end
                
            end
            new_ds = reorder_data(ds.data)
            #new_ds = add_xcel(new_ds, xcel_data)

            #reorder_data(ds.data).each_pair do |title, line|
            new_ds.each_pair do |title, line|    
                
                layout = {}
                line.each_pair do |data_set, d|
                    plot_data = []
                    layout = {width: 500, height: 500, title: "#{title} #{data_set}"}
                    d.each_pair do |label, dat|
                        
                        plot_data.push({
                            x: dat[:x],
                            y: dat[:y],
                            type: :scatter,
                            mode: 'markers',
                            name: label,
                            marker: ds.markers[label]
                        })
                    end
                    unless json
                        plot = Plotly::Plot.new(data: plot_data, layout: layout)
                        Dir.exist?("./graphs/#{title}") ? true : Dir.mkdir("./graphs/#{title}")
                        plot.generate_html(path: "./graphs/#{title}/#{data_set}.html", open: false)
                    end
                end
                       
            end
            new_ds
        end
=begin
reorderdata = {
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
        def add_xcel(ds, xcel_data)
            
        end
        def reorder_data(ds)
            new_ds = {}
            
            ds.keys.each do |label| #DHRL
                
                ds[label].keys.each do |graph| #x-RUU
                    unless new_ds[graph]
                        new_ds[graph] = {}
                    end

                    
                    ds[label][graph].keys.each do |line| #x0-line
                        unless new_ds[graph][line]
                            new_ds[graph][line] = {}
                        end
                        
                        new_ds[graph][line][label] = ds[label][graph][line]
                        
                    end 
                end
            end
            new_ds
        end
    end
end

=begin


 

First file: Y(mm), V at X=0, V at X=1, U at X=0, U at X=1,  uu at X=0, uu at X=1, uv at X=0, uv at X=1, vv at X=0, vv at X=1        

Second file: X(mm), (V(y/L=1),U(y/L=1),uu(y/L=1),uv(y/L=1),vv(y/L=1)....V(y/L=8),U(y/L=8),uu(y/L=8),uv(y/L=8),vv(y/L=8))
=end
