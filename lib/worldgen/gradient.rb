module WorldGen

def gradient(sample_values,x,&mixer_code)
	min_x = sample_values.last[0]
	max_x = sample_values.first[0]
	# ex. 3000
	return sample_values.last[1]  if x<=min_x
	return sample_values.first[1] if x>=max_x
	li = -1
	sample_values.each_with_index do |arr,i|
		sample_x,sample_value = arr
		li=i if x>sample_x and li==-1
	end
	# ex. li = 1
	delta = sample_values[li-1][0]-sample_values[li][0] # ex. 4000-1000 = 3000
	dalt = x-sample_values[li][0] # ex. 3000-1000 = 2000
	p = dalt.to_f/delta.to_f # ex. 2000/3000 = 0.66
	#ip = 1.0-p # ex. 0.33 =>  

	mixer_code.call(p,sample_values[li-1][1],sample_values[li][1])
end

def gradient_numbers(sample_values,x)
	gradient(sample_values,x) do |p,v_low,v_high|
		ip = 1.0-p
		p*v_low+ip*v_high
	end
end

end