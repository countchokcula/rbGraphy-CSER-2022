require "rbplotly"
require "byebug"
module Graphy3
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
                
            elsif @in_label # !line.include?(")") &&  within the last parenthesis #NOTE LOOK AT THIS
                
                points = line.split(' ').map(&:to_f)
                unless points[0].nil? || points[1].nil?
                    @data[name][file][@label][:x].push points[0]
                    @data[name][file][@label][:y].push points[1]
                end
                
            elsif line[0] == ')' #if last parenthesis
                @in_label = false
                
            end
        end

        def data
            @data
        end
    end

    class << self
        def ls
            Dir.entries("./data")
        end
        def check_dir
            ["data", "graphs"].each do |dir|
                Dir.exist?(dir) ? true : (Dir.mkdir(dir); puts "Created #{dir} folder")
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
        
       
        def read_files
            check_dir
            #Plotly.auth("jthoward17","90d0ohU0cfSMejNkUm0r")
            plot = Plotly::Plot.new
            
            Dir.empty?("./data") ? (puts "\nPlease put graph data in the data folder"; return) : false
            
            #ds = Dataset.new(get_titles)
            
            data_sets = []
            ds = Data.new
            data_set_names.each do |name| #DHRL DHRL66 ... ect
                ds.in_label = false; #NOTE: bad practice
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
                #data_sets.push(ds)
                
                
            end
            
           reorder_data ds.data
            
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
            
        end
    end
end
Graphy3.read_files