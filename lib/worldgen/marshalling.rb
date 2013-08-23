module WorldGen

def load_marshal_file(path)
	raise "Unexisting file: #{path}" unless File.exists? path
	data = []
	File.open(path, 'rb') {|file| data = Marshal.load(file) }
	data
end

def save_marshal_file(path,data)
	File.open(path, 'wb') {|file| Marshal.dump(data,file) }
end

end