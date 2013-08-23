module WorldGen

def cube_root(x)
  Math.exp(Math.log(x.to_f)/3.to_f)
end

def to_base(number,base,n_ciphers)
	if number<base 
		res = []
		(n_ciphers-1).times { res << 0 }
		res << number
		return res
	end
	last_cipher = number%base
	remaining = number-last_cipher	
	previous_part = remaining/base
	to_base(previous_part,base,n_ciphers-1) << last_cipher
end

end