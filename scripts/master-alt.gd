extends Node2D

# Common
export (String) var save;
export (String) var ld;

# AI
onready var ai_prefab = load("res://scenes/ai-alt.tscn");

# Weights
var W1 = [];
var W2 = [];
var W3 = [];

# Biases
var B1 = [];
var B2 = [];
var B3 = [];

# Statistics
var rounds = 1;

# Rngs
var rng = RandomNumberGenerator.new();

#################################################
#				Q Learning Process
#
#				Codes:
#				----------------	
#				0 is [1, 1]
#				1 is [1, -1]
#				2 is [-1, 1]
#				3 is [-1, -1]
#
#################################################

var gamma = 0.975;
var alpha = 0.003;
var tau = 0;

func Q_learn(old, O, reward, next_state, old_state, index):
	# House Keeping
	rounds += 1;
	
	if rounds % 5000 == 0:
		tau *= 0.99;
		
		if tau < 1e-12:
			tau = 0;
		
		print("Saving...");
		save();
	
	# Compute the Cost
	var true_value = old + alpha * (reward + gamma * \
		MaxReward(calculate(next_state)) - old);
	
	var cost = [[0], [0], [0], [0]];
	
	cost[index] = [true_value - old];
	
	print("cost:\t" + str(cost));
	print("tau:\t" + str(tau));
	
	# Compute the Gradient
	gradient(cost);
	
	# Applying gradients
	W1 = m_add(W1, dW1);
	W2 = m_add(W2, dW2);
	W3 = m_add(W3, dW3);
	
	B1 = v_add(B1, mtov(dB1));
	B2 = v_add(B2, mtov(dB2));
	B3 = v_add(B3, mtov(dB3));

func cost(O, A, R):
	var k = index(A);
	
	var cost = [];
	for i in range(0, 4):
		if i == k:
#			cost.append([O[i] - R]);
			cost.append([R - O[i]]);
		else:
			cost.append([0]);
	
	return cost;

func index(O):
	if O[0] == 1:
		if O[1] == 1:
			return 0;
		else:
			return 1;
	else:
		if O[1] == 1:
			return 2;
		else:
			return 3;
	return -1;

func MaxReward(O):
	var mx = O[0];
	
	for i in O:
		if i > mx:
			mx = i;
	
	return mx;

#################################################
#					Setup
#################################################

var rmax = 0.05;

func _ready():
	rng.randomize();
	
	print(ld);
	
	if ld == "":
		for i in range(0, 8):
			var outs = [];
			
			for j in range(0, 8):
				outs.append(rng.randf_range(-rmax, rmax));
			
			W1.append(outs);
			B1.append(rng.randf_range(-rmax, rmax));
			
		for i in range(0, 8):
			var outs = [];
			
			for j in range(0, 8):
				outs.append(rng.randf_range(-rmax, rmax));
			
			W2.append(outs);
			B2.append(rng.randf_range(-rmax, rmax));
		
		for i in range(0, 4):
			var outs = [];
			
			for j in range(0, 8):
				outs.append(rng.randf_range(-rmax, rmax));
			
			W3.append(outs);
			B3.append(rng.randf_range(-rmax, rmax));
	else:
		ld();
	
#	print("-------------------------------------------------------");
#	print("\tW1: " + str(W1));
#	print("\tW2: " + str(W2));
#	print("\tW3: " + str(W3));
#
#	print("\n\tB1: " + str(B1));
#	print("\tB2: " + str(B2));
#	print("\tB3: " + str(B3));
#
#	print("\nRounds: " + str(rounds));
#	print("\nTau: " + str(tau));
#	print("-------------------------------------------------------\n");
	
#	get_node("Camera2D").current = true;
	
	var env = get_parent().get_node("environments");
	
	for i in range(0, env.get_child_count()):
		var car = ai_prefab.instance();
		
		car.spawn = env.get_child(i).get_child(0).get_path();
		
		add_child(car);

func save():
	var fout = File.new();
	
	var err = fout.open(save, File.WRITE);
	
	if err != OK:
		printerr("Invalid Save Destination");
		return;
	
	var string = "";
	
	string += "W1: " + str(W1);
	string += "\nW2: " + str(W2);
	string += "\nW3: " + str(W3);
	
	string += "\n\nB1: " + str(B1);
	string += "\nB2: " + str(B2);
	string += "\nB3: " + str(B3);
	
	string += "\n\nRounds: " + str(rounds);
	string += "\nTau: " + str(tau);
	
	fout.store_string(string);

func ld():
	var fin = File.new();
	
	var err = fin.open(save, File.READ);
	
	if err != OK:
		printerr("Invalid Load Destination");
		return;
	
	var content = fin.get_as_text();
	
	var all = Array(content.split("\n"));
	
	var weights = all.slice(0, 2);
	var biases = all.slice(4, 6);
	var rest = all.slice(7, 10);
	
	var tmp_weights = [];
	for line in weights:
		var spl = line.split(": ");
		
		var s = spl[1];
		
		var sh = s.substr(2, s.length() - 4).split("], [");
		
		var tmp_flt_ws = [];
		
		for i in sh:
			var arr = Array(i.split(", "));
			
			var tmp_flt_arr = [];
			
			for j in arr:
				tmp_flt_arr.append(float(j));
			
			tmp_flt_ws.append(tmp_flt_arr);
		
		tmp_weights.append(tmp_flt_ws);
	
	W1 = tmp_weights[0];
	W2 = tmp_weights[1];
	W3 = tmp_weights[2];
	
	print(W1);
	
	var tmp_biases = [];
	for line in biases:
		var spl = line.split(": ");
		
		var s = spl[1];
		
		var sstr = s.substr(1, s.length() - 2);
		
		var arr = Array(sstr.split(", "));
		
		var tmp_flt_arr = [];
		
		for i in arr:
			tmp_flt_arr.append(float(i));
		
		tmp_biases.append(tmp_flt_arr);
	
	B1 = tmp_biases[0];
	B2 = tmp_biases[1];
	B3 = tmp_biases[2];
	
	print(tmp_biases);
	
	rounds = int((all[8].split(": "))[1]);
	tau = float((all[9].split(": "))[1]);
	
	pass;

#################################################
#				Network Settings
#################################################

# Leaky ReLU
var beta = 0.01;

func act(x):
	if x > 0:
		return x;
	return beta * x;

func d_act(x):
	if x > 0:
		return 1;
	else:
		return beta;

#################################################
#				Linear Algebra
#################################################

var M0 = [];
var M1 = [];
var M2 = [];

# Array of predicted rewards
var O = [];

var Z1 = [];
var Z2 = [];
var Z3 = [];

# Linear Algebra

func calculate(X):
	# State Saving
	M0 = X;
	
	Z1 = fma(W1, M0, B1);
	M1 = vtanh(Z1);
	
	Z2 = fma(W2, M1, B2);
	M2 = vtanh(Z2);
	
	Z3 = fma(W3, M2, B3);
	O = vact(Z3);
	
	return O;


func dot(a, b):
	var tmp = 0;
	
	# Speed up to log(n) addition if needed
	for i in range(0, a.size()):
		tmp += a[i] * b[i];
	
	return tmp;

func m_sclr(A, x):
	var out = [];
	
	for i in A:
		var row = [];
		
		for j in i:
			row.append(x * j);
		
		out.append(row);
	
	return out;

func v_sclr(A, x):
	var out = [];
	
	for i in A:
		out.append(x * i);
	
	return out;

func transpose(M):
	var size = M[0].size();
	
	var Mt = [];
	
	for i in range(0, size):
		var row = [];
		
		for j in range(0, M.size()):
			row.append(M[j][i]);
		
		Mt.append(row);
	
	return Mt;

func vtom(M):
	var out = [];
	
	for i in M:
		out.append([i]);
	
	return out;

func mtov(M):
	var out = [];
	
	for i in M:
		out.append(i[0]);
	
	return out;

var _mult_row;
var _mult_t;
var _mult_out;

func mult(A, B):
	_mult_out = [];
	
	assert(A[0].size() == B.size());
	
	var sx = A.size();
	var sy = B[0].size();
	var ms = B.size();
	
	for i in range(0, sx):
		_mult_row = []
		for j in range(0, sy):
			_mult_t = 0;
			
			for k in range(0, ms):
				_mult_t += A[i][k] * B[k][j];
		
			_mult_row.append(_mult_t);
		
		_mult_out.append(_mult_row);
	
	return _mult_out;

func m_add(A, B):
	assert(A.size() == B.size()
		and A[0].size() == B[0].size());
	
	var sx = A.size();
	var sy = A[0].size();
	
	var out = [];
	
	for i in range(0, sx):
		var row = [];
		
		for j in range(0, sy):
			row.append(A[i][j] + B[i][j]);
		
		out.append(row);
	
	return out;

func v_add(A, B):
	assert(A.size() == B.size());
	
	var sz = A.size();
	
	var out = [];
	
	for i in range(0, sz):
		out.append(A[i] + B[i]);
	
	return out;

func shur(A, B):
	assert(A.size() == B.size()
		and A[0].size() == B[0].size());
	
	var sx = A.size();
	var sy = A[0].size();
	
	var out = [];
	
	for i in range(0, sx):
		var row = [];
		
		for j in range(0, sy):
			row.append(A[i][j] * B[i][j]);
		
		out.append(row);
	
	return out;

var _Mk;
var _sz;

# Specific
func fma(M, I, B):
	var out = [];
	
	_sz = M.size();
	for k in range(0, _sz):
		
		_Mk = M[k];
		out.append(_Mk[0] * I[0]
			+ _Mk[1] * I[1]
			+ _Mk[2] * I[2]
			+ _Mk[3] * I[3]
			+ _Mk[4] * I[4]
			+ _Mk[5] * I[5]
			+ _Mk[6] * I[6]
			+ _Mk[7] * I[7]
			+ B[k]);
	
	return out;

func vtanh(A):
	var O = [];
	
	for i in A:
		O.append(tanh(i));
	
	return O;

# Derivative of activation
func dtanh(x):
	var t = cosh(x);
	
	return 1/(t * t);

func vdtanh(A):
	var O = [];
	
	for i in A:
		O.append([dtanh(i)]);
	
	return O;

func vact(A):
	var O = [];
	
	for i in A:
		O.append(act(i));
	
	return O;

func vd_act(A):
	var O = [];
	
	for i in A:
		O.append([d_act(i)]);
	
	return O;

# GD
var dW1 = [];
var dW2 = [];
var dW3 = [];

var dB1 = [];
var dB2 = [];
var dB3 = [];

func gradient(Cost):
	var dZ1 = vdtanh(Z1);
	var dZ2 = vdtanh(Z2);
	
	var dZ3 = vd_act(Z3);
	
	dB3 = shur(dZ3, Cost);
	dB2 = shur(mult(transpose(W3), dB3), dZ2);
	dB1 = shur(mult(transpose(W2), dB2), dZ1);
	
	dW3 = mult(dB3, transpose(vtom(M2)));
	dW2 = mult(dB2, transpose(vtom(M1)));
	dW1 = mult(dB1, transpose(vtom(M0)));
