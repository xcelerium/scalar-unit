import math
import cocotb
import numpy as np

def enum(x):
  return {value:index for index, value in enumerate(x)}

# Enums
mult_precision = enum(["MULT_32", "MULT_16", "MULT_16C", "MULT_8", "MULT_32_BY_16"])
mult_operation = enum(["MULT", "MULTH", "MULTW", "MULTACC", "NONLINEAR_1", "NONLINEAR_2"])

# Structs
mult_flags_config = [("acc_init", 1), ("acc_final", 1) , ("multw_round", 1)]
mult_params_config = [("flags", mult_flags_config), ("is_signed", 1), ("rnd_position", 7), ("output_int_bits", 1)]

def np_to_bin(array, width, elems_to_combine = 1):
  """
  turns numpy array to binary; if elems_to_combine > 1, concatenates that many consecutive strings
  """
  temp = [x[-width:] for x in list(np.vectorize(np.binary_repr)(array, width))]
  result = []
  for i in range(len(temp)//elems_to_combine):
    result.append("".join(temp[:elems_to_combine]))
    temp = temp[elems_to_combine:]
  return result

def CocotbBin(x):
  return cocotb.binary.BinaryValue(x)

def gen_zeros(width,num_tests):
  bin_version = ["0" for x in np.random.randint(0,2,width)]
  bin_str_version = "".join(bin_version)
  return bin_str_version

def gen_ones(width,num_tests):
  bin_version = ["1" for x in np.random.randint(0,2,width)]
  bin_str_version = "".join(bin_version)
  return bin_str_version

def generate_bin_array(width, num_tests):
  bin_version = [str(x) for x in np.random.randint(0, 2, width)]
  bin_str_version = "".join(bin_version)
  return bin_str_version

def generate_b_shift(width, num_tests):
  bin_byte = ''
  for byt in range(int(width/8)):
    bin_version = [str(x) for x in np.random.randint(0, 2, 3)]
    bin_byte += '00000' + "".join(bin_version)
  return bin_byte

def generate_hw_shift(width, num_tests):
  bin_byte = ''
  for byt in range(int(width/16)):
    bin_version = [str(x) for x in np.random.randint(0,2,4)]
    bin_byte += gen_zeros(16-4,1) + "".join(bin_version)
  return bin_byte

def generate_w_shift(width, num_tests):
  bin_byte = ''
  for byt in range(int(width/32)):
    bin_version = [str(x) for x in np.random.randint(0,2,5)]
    bin_byte += gen_zeros(32-5,1) + "".join(bin_version)
  return bin_byte

def generate_dw_shift(width,num_tests):
  bin_version = [str(x) for x in np.random.randint(0,2,6)]
  return gen_zeros(width-6,num_tests) + "".join(bin_version) #return gen_zeros(width-5,num_tests)+'10000'

def generate_shift(width, num_tests):
  zero_extend = gen_zeros(width-3-8,num_tests)
  return '00000011'+zero_extend+'011'

def generate_random_array(width, num_tests, precision=8, signed=True, gen_bytes = False, shifting = False, genz = False, geno = False, elems_to_combine = 1, data_range=None):
  """
  returns np_array, binary_array
    For <64 bits, generates numpy array for manipulation and a list of bit strings
    For > 64 bits, returns list of bit strings. If divisible by 8, also returns
    list of bytes, otherwise return None as np_array
  """

  if (width < 64 and not gen_bytes): # Generate standard numpy array
    dtype = 8 if width <= 8 else 16 if width <= 16 else 32 if width <= 32 else 64
    dtype_str = ("int" if signed else "uint") + str(dtype)
    min_val = -2**(width - 1) if signed else 0
    max_val = 2**(width - 1) if signed else 2**width

    # Manual range override
    if (data_range is not None):
      (min_val, max_val) = data_range

    data = np.random.randint(min_val, max_val, num_tests, dtype = dtype_str)
    data_bin = np_to_bin(data, width, elems_to_combine)
  else: # Generate manually with no numpy array output
    assert width % 8 == 0, "Bit width must be divisible by 8 when generating bytes"
    num_bytes = width // 8
    #data = [np.random.randint(-2**7, 2**7, num_bytes, dtype="int8") for i in range(num_elems)]
    #data_bin = [generate_bin_array(width, num_elems) for i in range(num_elems)] #wtf? this isn't even the same array
    data_bin = []
    data = []
    for i in range(num_tests):
      if(genz == True): #make data all zeros
        bin_version = gen_zeros(width,num_tests)
      elif(geno == True): #make data all ones
        bin_version = gen_ones(width,num_tests)
      elif(shifting == False): #make random data
        bin_version = generate_bin_array(width,num_tests)
      else: #make shift value
        if(precision == 64): #dword shift
          bin_version = generate_dw_shift(width,num_tests)
        elif(precision == 32): #word
          bin_version = generate_w_shift(width,num_tests)
        elif(precision == 16): #hword
          bin_version = generate_hw_shift(width,num_tests)
        elif(precision == 8): #byte shift
          bin_version = generate_b_shift(width,num_tests)
      data_bin.append(bin_version)
      if(signed == True):
        data.append([CocotbBin(bin_version[j*8:j*8+8]).signed_integer for j in range(num_bytes)]) 
      else:
        data.append([CocotbBin(bin_version[j*8:j*8+8]).integer for j in range(num_bytes)])
  return data, data_bin

def pack_struct(data, config, base=True):
   """
   Converts dictionary into a bit-vector based on a config
      data:    dictionary of {name: value} where value can be binary, hex, or int
                  ex: {"data": 16, "val":1}
      config: ordered list of tuples (name, bit_width) for each field of a struct to pack
                  ex: [("data", 8), ("val", 1)]
      base:    indicates that this is a top-level call rather than a recursive sub-call
                  (used to format sub-calls as strings but top-level calls as CocotbBin)

      return: binary bit-vector (packed fields)
                  ex: "0000100001"
   """
   # base indicates whether it is top-level call rather than a recursive sub-call
   output = ""

   # Loop through config in order
   for x in config:
      # If this field is not a nested struct
      if (type(x[1]) == int):

         # If int, convert to binary string
         if (type(data[x[0]]) == int):
            output += np.binary_repr(data[x[0]], x[1])
         # String (hex or binary)
         elif (type(data[x[0]]) == str):
            if (len(data[x[0]]) > 1 and data[x[0]][:2] == "0x"): # Hex
               output += np.binary_repr(int(data[x[0]], 16), x[1])
            else: # Binary
               output += data[x[0]]

      # Nested Struct
      else:
         output += pack_struct(data[x[0]], x[1], base=False)

   # If top-level, wrap with CocotbBin; else output string
   return CocotbBin(output) if base else output


def unpack_struct(data, config):
   data_val = data.value.binstr
   output = {}
   for x in config:
      output[x[0]] = hex_zero_padded(int(data_val[:x[1]], 2), math.ceil(x[1]/4))
      data_val = data_val[x[1]:]
   return output

def hex_zero_padded(value, length):
   """
   Return hex value of integer with zero padding
   """
   return "{0:#0{1}x}".format(value, length+2)

def binstr_to_int (binstr_arr):
  return [int(x,2) for x in binstr_arr]

def int_to_bin(s):
  return str(s) if s<=1 else bin(s>>1) + str(s&1)

def pack_matrix_to_vec (matrix, elem_width):
  vec_arr = []
  for x in matrix:
    vec_arr.append ("".join(np_to_bin(np.flipud(x),elem_width)))
  return vec_arr

def get_op_part(funct):
  if(funct == 'SRA'):
    signed_bool = True
    is_signed = 1
    shift_dir = 0
  elif(funct == 'SLA'):
    signed_bool = True
    is_signed = 1
    shift_dir = 1
  elif(funct == 'SLL'):
    signed_bool = False
    is_signed = 0
    shift_dir = 1
  elif(funct == 'SRL'):
    signed_bool = False
    is_signed = 0
    shift_dir = 0
  return signed_bool, is_signed, shift_dir

def object_list_to_int_list (object_list,signed=True):
    result = []
    num_tests = len(object_list)
    num_bytes = len(object_list[0])
    for i in range(num_tests):
        result.append([])
        for j in range(num_bytes):
	    #note that bytes are backwards so we reverse them herear
            #result[i].append((object_list[i][num_bytes-1-j]).value.binstr)
            if(signed == True):
                result[i].append(((object_list[i][num_bytes-1-j]).value).signed_integer)
            else:
                result[i].append(((object_list[i][num_bytes-1-j]).value).integer)
    return result

def check_shift(expected_data,result_data):
	equality = True
	for x in range(len(expected_data)):
		if(expected_data[x] != result_data[x]):
			equality = False
	return equality

def check_rounded(expected,result,num_tests,num_bytes=256):
	num_correct = 0
	for x in range(num_tests):
		for byte_num in range(num_bytes):
			if((expected[x][byte_num] == result[x][byte_num] or expected[x][byte_num] == (result[x][byte_num]+1) or expected[x][byte_num] == (result[x][byte_num]-1))):
				num_correct += 1
				break
			else:
				print("Case failed")
				print("Expected ",expected[x][byte_num])
				print("Received ",result[x][byte_num])
	return num_correct

def data_equality(expected_data,result_data):
	equality = True
	for y in range(len(expected_data)):
		if(expected_data[y] != result_data[y]):
			equality = False
	return equality

def check_equality(a, b, expected,result,num_tests):
	num_correct = 0
	for x in range(num_tests):
		if(data_equality(expected[x],result[x])):
			num_correct += 1
			print("Passed 1")
		else:
			print("Case failed")
			print("A", a)
			print("B", b)
			print("Expected ",expected[x])
			print("Received ",result[x])
	return num_correct

def red(expected,precision):
	red = 0
	num_bytes = int(precision/8)
	for byte in range(num_bytes):
		red += expected[len(expected)-byte-1]
	return red

def red_list(expected_list,precision):
	redl = []
	for x in expected_list:
		redl.append(red(x,precision))
	return redl

def red_result(result):
	red = []
	for x in result:
		red.append(x[len(x)-1])
	return red

def binstr_to_dtype(binstr,dtype):
	data = []
	#for i in range(num_tests):
	if(dtype == 'int8'):
		num_elems = int(len(binstr)/8)
		data = [CocotbBin(binstr[j*8:j*8+8]).signed_integer for j in range(num_elems)]
	elif(dtype == 'uint8'):
		num_elems = int(len(binstr)/8)
		data = [CocotbBin(binstr[j*8:j*8+8]).integer for j in range(num_elems)]
	elif(dtype == 'int16'):
		num_elems = int(len(binstr)/16)
		data = [CocotbBin(binstr[j*16:j*16+16]).signed_integer for j in range(num_elems)]
	elif(dtype == 'uint16'):
		num_elems = int(len(binstr)/16)
		data = [CocotbBin(binstr[j*16:j*16+16]).integer for j in range(num_elems)]
	elif(dtype == 'int32'):
		num_elems = int(len(binstr)/32)
		data = [CocotbBin(binstr[j*32:j*32+32]).signed_integer for j in range(num_elems)]
	elif(dtype == 'uint32'):
		num_elems = int(len(binstr)/32)
		data = [CocotbBin(binstr[j*32:j*32+32]).integer for j in range(num_elems)]
	elif(dtype == 'int64'):
		num_elems = int(len(binstr)/64)
		data = [CocotbBin(binstr[j*64:j*64+64]).signed_integer for j in range(num_elems)]
	elif(dtype == 'uint64'):
		num_elems = int(len(binstr)/64)
		data = [CocotbBin(binstr[j*64:j*64+64]).integer for j in range(num_elems)]
	return data

def generate_random_matrix(dimension, num_tests, precision=8, signed=True, gen_bytes = False, shifting = False, genz = False, geno = False, elems_to_combine = 1, data_range=None):
  """
  returns np_array, binary_array
    For <64 bits, generates numpy array for manipulation and a list of bit strings
    For > 64 bits, returns list of bit strings. If divisible by 8, also returns
    list of bytes, otherwise return None as np_array
  """
  width = dimension*dimension*precision

  if (width < 64 and not gen_bytes): # Generate standard numpy array
    dtype = 8 if width <= 8 else 16 if width <= 16 else 32 if width <= 32 else 64
    dtype_str = ("int" if signed else "uint") + str(dtype)
    min_val = -2**(width - 1) if signed else 0
    max_val = 2**(width - 1) if signed else 2**width

    # Manual range override
    if (data_range is not None):
      (min_val, max_val) = data_range

    data = np.random.randint(min_val, max_val, num_tests, dtype = dtype_str)
    data_bin = np_to_bin(data, width, elems_to_combine)
  else: # Generate manually with no numpy array output
    assert width % 8 == 0, "Bit width must be divisible by 8 when generating bytes"
    num_bytes = width // 8
    #data = [np.random.randint(-2**7, 2**7, num_bytes, dtype="int8") for i in range(num_elems)]
    #data_bin = [generate_bin_array(width, num_elems) for i in range(num_elems)] #wtf? this isn't even the same array
    data_bin = []
    data = []
    data_2d = []
    for i in range(num_tests):
      if(genz == True): #make data all zeros
        bin_version = gen_zeros(width,num_tests)
      elif(geno == True): #make data all ones
        bin_version = gen_ones(width,num_tests)
      elif(shifting == False): #make random data
        bin_version = generate_bin_array(width,num_tests)
      else: #make shift value
        if(precision == 64): #dword shift
          bin_version = generate_dw_shift(width,num_tests)
        elif(precision == 32): #word
          bin_version = generate_w_shift(width,num_tests)
        elif(precision == 16): #hword
          bin_version = generate_hw_shift(width,num_tests)
        elif(precision == 8): #byte shift
          bin_version = generate_b_shift(width,num_tests)
      data_bin.append(bin_version)
      if(signed == True):
        data.append([CocotbBin(bin_version[j*8:j*8+8]).signed_integer for j in range(num_bytes)]) 
      else:
        data.append([CocotbBin(bin_version[j*8:j*8+8]).integer for j in range(num_bytes)])
      data_2d.append([[data[i][x*dimension+y] for x in range(dimension)] for y in range(dimension)])
  return data_2d, data_bin

