local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 79) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local FlatIdent_12703 = 0;
			local a;
			while true do
				if (FlatIdent_12703 == 0) then
					a = Char(StrToNumber(byte, 16));
					if repeatNext then
						local b = Rep(a, repeatNext);
						repeatNext = nil;
						return b;
					else
						return a;
					end
					break;
				end
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local FlatIdent_2BD95 = 0;
			local Res;
			while true do
				if (FlatIdent_2BD95 == 0) then
					Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
					return Res - (Res % 1);
				end
			end
		else
			local FlatIdent_23BE8 = 0;
			local Plc;
			while true do
				if (FlatIdent_23BE8 == 0) then
					Plc = 2 ^ (Start - 1);
					return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
				end
			end
		end
	end
	local function gBits8()
		local FlatIdent_8199B = 0;
		local a;
		while true do
			if (FlatIdent_8199B == 0) then
				a = Byte(ByteString, DIP, DIP);
				DIP = DIP + 1;
				FlatIdent_8199B = 1;
			end
			if (1 == FlatIdent_8199B) then
				return a;
			end
		end
	end
	local function gBits16()
		local a, b = Byte(ByteString, DIP, DIP + 2);
		DIP = DIP + 2;
		return (b * 256) + a;
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local FlatIdent_5ED46 = 0;
		local Left;
		local Right;
		local IsNormal;
		local Mantissa;
		local Exponent;
		local Sign;
		while true do
			if (2 == FlatIdent_5ED46) then
				Exponent = gBit(Right, 21, 31);
				Sign = ((gBit(Right, 32) == 1) and -1) or 1;
				FlatIdent_5ED46 = 3;
			end
			if (3 == FlatIdent_5ED46) then
				if (Exponent == 0) then
					if (Mantissa == 0) then
						return Sign * 0;
					else
						local FlatIdent_940A0 = 0;
						while true do
							if (FlatIdent_940A0 == 0) then
								Exponent = 1;
								IsNormal = 0;
								break;
							end
						end
					end
				elseif (Exponent == 2047) then
					return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
				end
				return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
			end
			if (FlatIdent_5ED46 == 1) then
				IsNormal = 1;
				Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
				FlatIdent_5ED46 = 2;
			end
			if (FlatIdent_5ED46 == 0) then
				Left = gBits32();
				Right = gBits32();
				FlatIdent_5ED46 = 1;
			end
		end
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local FlatIdent_49AED = 0;
			local Type;
			local Cons;
			while true do
				if (FlatIdent_49AED == 1) then
					if (Type == 1) then
						Cons = gBits8() ~= 0;
					elseif (Type == 2) then
						Cons = gFloat();
					elseif (Type == 3) then
						Cons = gString();
					end
					Consts[Idx] = Cons;
					break;
				end
				if (FlatIdent_49AED == 0) then
					Type = gBits8();
					Cons = nil;
					FlatIdent_49AED = 1;
				end
			end
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					local FlatIdent_65290 = 0;
					while true do
						if (FlatIdent_65290 == 0) then
							Inst[3] = gBits16();
							Inst[4] = gBits16();
							break;
						end
					end
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					local FlatIdent_7A75F = 0;
					while true do
						if (FlatIdent_7A75F == 0) then
							Inst[3] = gBits32() - (2 ^ 16);
							Inst[4] = gBits16();
							break;
						end
					end
				end
				if (gBit(Mask, 1, 1) == 1) then
					Inst[2] = Consts[Inst[2]];
				end
				if (gBit(Mask, 2, 2) == 1) then
					Inst[3] = Consts[Inst[3]];
				end
				if (gBit(Mask, 3, 3) == 1) then
					Inst[4] = Consts[Inst[4]];
				end
				Instrs[Idx] = Inst;
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				local FlatIdent_1B1BA = 0;
				while true do
					if (FlatIdent_1B1BA == 0) then
						Inst = Instr[VIP];
						Enum = Inst[1];
						FlatIdent_1B1BA = 1;
					end
					if (FlatIdent_1B1BA == 1) then
						if (Enum <= 26) then
							if (Enum <= 12) then
								if (Enum <= 5) then
									if (Enum <= 2) then
										if (Enum <= 0) then
											Stk[Inst[2]] = {};
										elseif (Enum == 1) then
											local B;
											local A;
											A = Inst[2];
											Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
										else
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										end
									elseif (Enum <= 3) then
										VIP = Inst[3];
									elseif (Enum > 4) then
										local B;
										local A;
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = {};
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										local A = Inst[2];
										Stk[A] = Stk[A]();
									end
								elseif (Enum <= 8) then
									if (Enum <= 6) then
										local Edx;
										local Results, Limit;
										local B;
										local A;
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]]();
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									elseif (Enum == 7) then
										local B;
										local A;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									elseif (Inst[2] == Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif (Enum <= 10) then
									if (Enum > 9) then
										local B;
										local A;
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										local FlatIdent_8DCA9 = 0;
										local A;
										while true do
											if (FlatIdent_8DCA9 == 0) then
												A = Inst[2];
												Stk[A](Stk[A + 1]);
												break;
											end
										end
									end
								elseif (Enum == 11) then
									local Edx;
									local Results, Limit;
									local B;
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								else
									local FlatIdent_39EBF = 0;
									local NewProto;
									local NewUvals;
									local Indexes;
									while true do
										if (FlatIdent_39EBF == 0) then
											NewProto = Proto[Inst[3]];
											NewUvals = nil;
											FlatIdent_39EBF = 1;
										end
										if (FlatIdent_39EBF == 2) then
											for Idx = 1, Inst[4] do
												local FlatIdent_189F0 = 0;
												local Mvm;
												while true do
													if (FlatIdent_189F0 == 1) then
														if (Mvm[1] == 35) then
															Indexes[Idx - 1] = {Stk,Mvm[3]};
														else
															Indexes[Idx - 1] = {Upvalues,Mvm[3]};
														end
														Lupvals[#Lupvals + 1] = Indexes;
														break;
													end
													if (FlatIdent_189F0 == 0) then
														VIP = VIP + 1;
														Mvm = Instr[VIP];
														FlatIdent_189F0 = 1;
													end
												end
											end
											Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
											break;
										end
										if (1 == FlatIdent_39EBF) then
											Indexes = {};
											NewUvals = Setmetatable({}, {__index=function(_, Key)
												local Val = Indexes[Key];
												return Val[1][Val[2]];
											end,__newindex=function(_, Key, Value)
												local FlatIdent_35A31 = 0;
												local Val;
												while true do
													if (FlatIdent_35A31 == 0) then
														Val = Indexes[Key];
														Val[1][Val[2]] = Value;
														break;
													end
												end
											end});
											FlatIdent_39EBF = 2;
										end
									end
								end
							elseif (Enum <= 19) then
								if (Enum <= 15) then
									if (Enum <= 13) then
										local A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
									elseif (Enum > 14) then
										local FlatIdent_8D1A5 = 0;
										local B;
										local A;
										while true do
											if (4 == FlatIdent_8D1A5) then
												Stk[Inst[2]] = {};
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]][Inst[3]] = Inst[4];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_8D1A5 = 5;
											end
											if (FlatIdent_8D1A5 == 0) then
												B = nil;
												A = nil;
												A = Inst[2];
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												Stk[A] = B[Inst[4]];
												FlatIdent_8D1A5 = 1;
											end
											if (FlatIdent_8D1A5 == 2) then
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												FlatIdent_8D1A5 = 3;
											end
											if (5 == FlatIdent_8D1A5) then
												Stk[Inst[2]][Inst[3]] = Inst[4];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												FlatIdent_8D1A5 = 6;
											end
											if (6 == FlatIdent_8D1A5) then
												Inst = Instr[VIP];
												Stk[Inst[2]] = Env[Inst[3]];
												break;
											end
											if (FlatIdent_8D1A5 == 1) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												FlatIdent_8D1A5 = 2;
											end
											if (3 == FlatIdent_8D1A5) then
												Stk[A] = B[Inst[4]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_8D1A5 = 4;
											end
										end
									else
										local A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
								elseif (Enum <= 17) then
									if (Enum > 16) then
										Upvalues[Inst[3]] = Stk[Inst[2]];
									else
										local B;
										local A;
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									end
								elseif (Enum > 18) then
									local A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								else
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								end
							elseif (Enum <= 22) then
								if (Enum <= 20) then
									local FlatIdent_7F121 = 0;
									local B;
									local A;
									while true do
										if (FlatIdent_7F121 == 4) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											FlatIdent_7F121 = 5;
										end
										if (FlatIdent_7F121 == 3) then
											A = Inst[2];
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											FlatIdent_7F121 = 4;
										end
										if (FlatIdent_7F121 == 2) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_7F121 = 3;
										end
										if (FlatIdent_7F121 == 1) then
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											FlatIdent_7F121 = 2;
										end
										if (FlatIdent_7F121 == 5) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											break;
										end
										if (FlatIdent_7F121 == 0) then
											B = nil;
											A = nil;
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											FlatIdent_7F121 = 1;
										end
									end
								elseif (Enum == 21) then
									if (Stk[Inst[2]] == Inst[4]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local Edx;
									local Results, Limit;
									local B;
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										local FlatIdent_6A091 = 0;
										while true do
											if (FlatIdent_6A091 == 0) then
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
												break;
											end
										end
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
								end
							elseif (Enum <= 24) then
								if (Enum > 23) then
									for Idx = Inst[2], Inst[3] do
										Stk[Idx] = nil;
									end
								elseif (Stk[Inst[2]] == Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum == 25) then
								Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
							else
								local B;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 39) then
							if (Enum <= 32) then
								if (Enum <= 29) then
									if (Enum <= 27) then
										local FlatIdent_882F4 = 0;
										local B;
										local A;
										while true do
											if (FlatIdent_882F4 == 1) then
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Stk[Inst[3]];
												FlatIdent_882F4 = 2;
											end
											if (FlatIdent_882F4 == 7) then
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Stk[Inst[3]];
												break;
											end
											if (FlatIdent_882F4 == 6) then
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												FlatIdent_882F4 = 7;
											end
											if (FlatIdent_882F4 == 0) then
												B = nil;
												A = nil;
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_882F4 = 1;
											end
											if (FlatIdent_882F4 == 2) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												FlatIdent_882F4 = 3;
											end
											if (FlatIdent_882F4 == 4) then
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_882F4 = 5;
											end
											if (FlatIdent_882F4 == 3) then
												Stk[A] = B[Inst[4]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												FlatIdent_882F4 = 4;
											end
											if (FlatIdent_882F4 == 5) then
												A = Inst[2];
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												Stk[A] = B[Inst[4]];
												VIP = VIP + 1;
												FlatIdent_882F4 = 6;
											end
										end
									elseif (Enum > 28) then
										local B;
										local A;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = {};
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										local B;
										local A;
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									end
								elseif (Enum <= 30) then
									Stk[Inst[2]]();
								elseif (Enum == 31) then
									local A = Inst[2];
									local Cls = {};
									for Idx = 1, #Lupvals do
										local List = Lupvals[Idx];
										for Idz = 0, #List do
											local FlatIdent_272FB = 0;
											local Upv;
											local NStk;
											local DIP;
											while true do
												if (FlatIdent_272FB == 0) then
													Upv = List[Idz];
													NStk = Upv[1];
													FlatIdent_272FB = 1;
												end
												if (1 == FlatIdent_272FB) then
													DIP = Upv[2];
													if ((NStk == Stk) and (DIP >= A)) then
														Cls[DIP] = NStk[DIP];
														Upv[1] = Cls;
													end
													break;
												end
											end
										end
									end
								else
									local Edx;
									local Results, Limit;
									local B;
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum <= 35) then
								if (Enum <= 33) then
									local A = Inst[2];
									local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									local Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
								elseif (Enum == 34) then
									local Edx;
									local Results, Limit;
									local B;
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										local FlatIdent_628E3 = 0;
										while true do
											if (FlatIdent_628E3 == 0) then
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
												break;
											end
										end
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								else
									Stk[Inst[2]] = Stk[Inst[3]];
								end
							elseif (Enum <= 37) then
								if (Enum == 36) then
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									Stk[Inst[2]] = Inst[3] ~= 0;
								end
							elseif (Enum > 38) then
								Stk[Inst[2]][Inst[3]] = Inst[4];
							else
								do
									return;
								end
							end
						elseif (Enum <= 46) then
							if (Enum <= 42) then
								if (Enum <= 40) then
									Stk[Inst[2]] = not Stk[Inst[3]];
								elseif (Enum > 41) then
									local FlatIdent_2E34E = 0;
									local B;
									local A;
									while true do
										if (FlatIdent_2E34E == 4) then
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											VIP = VIP + 1;
											FlatIdent_2E34E = 5;
										end
										if (FlatIdent_2E34E == 6) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_2E34E = 7;
										end
										if (FlatIdent_2E34E == 7) then
											VIP = Inst[3];
											break;
										end
										if (FlatIdent_2E34E == 0) then
											B = nil;
											A = nil;
											A = Inst[2];
											B = Stk[Inst[3]];
											FlatIdent_2E34E = 1;
										end
										if (1 == FlatIdent_2E34E) then
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_2E34E = 2;
										end
										if (FlatIdent_2E34E == 5) then
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A](Stk[A + 1]);
											VIP = VIP + 1;
											FlatIdent_2E34E = 6;
										end
										if (FlatIdent_2E34E == 2) then
											A = Inst[2];
											Stk[A](Stk[A + 1]);
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_2E34E = 3;
										end
										if (FlatIdent_2E34E == 3) then
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											FlatIdent_2E34E = 4;
										end
									end
								else
									local B;
									local A;
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum <= 44) then
								if (Enum == 43) then
									local FlatIdent_912A7 = 0;
									local A;
									local B;
									while true do
										if (FlatIdent_912A7 == 0) then
											A = Inst[2];
											B = Stk[Inst[3]];
											FlatIdent_912A7 = 1;
										end
										if (FlatIdent_912A7 == 1) then
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											break;
										end
									end
								else
									local FlatIdent_5724B = 0;
									local Edx;
									local Results;
									local Limit;
									local A;
									while true do
										if (FlatIdent_5724B == 5) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											break;
										end
										if (2 == FlatIdent_5724B) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											FlatIdent_5724B = 3;
										end
										if (0 == FlatIdent_5724B) then
											Edx = nil;
											Results, Limit = nil;
											A = nil;
											A = Inst[2];
											FlatIdent_5724B = 1;
										end
										if (FlatIdent_5724B == 3) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A]();
											FlatIdent_5724B = 4;
										end
										if (4 == FlatIdent_5724B) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											FlatIdent_5724B = 5;
										end
										if (FlatIdent_5724B == 1) then
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												local FlatIdent_44100 = 0;
												while true do
													if (FlatIdent_44100 == 0) then
														Edx = Edx + 1;
														Stk[Idx] = Results[Edx];
														break;
													end
												end
											end
											FlatIdent_5724B = 2;
										end
									end
								end
							elseif (Enum == 45) then
								local B;
								local A;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								Stk[Inst[2]] = Inst[3];
							end
						elseif (Enum <= 49) then
							if (Enum <= 47) then
								local B;
								local A;
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							elseif (Enum == 48) then
								local B;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local FlatIdent_4D83A = 0;
								while true do
									if (6 == FlatIdent_4D83A) then
										VIP = Inst[3];
										break;
									end
									if (FlatIdent_4D83A == 4) then
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_4D83A = 5;
									end
									if (FlatIdent_4D83A == 1) then
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_4D83A = 2;
									end
									if (FlatIdent_4D83A == 3) then
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_4D83A = 4;
									end
									if (0 == FlatIdent_4D83A) then
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_4D83A = 1;
									end
									if (FlatIdent_4D83A == 2) then
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_4D83A = 3;
									end
									if (FlatIdent_4D83A == 5) then
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_4D83A = 6;
									end
								end
							end
						elseif (Enum <= 51) then
							if (Enum > 50) then
								local Edx;
								local Results, Limit;
								local B;
								local A;
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3] ~= 0;
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]]();
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								Stk[Inst[2]] = Env[Inst[3]];
							end
						elseif (Enum > 52) then
							Stk[Inst[2]] = Upvalues[Inst[3]];
						elseif not Stk[Inst[2]] then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
						VIP = VIP + 1;
						break;
					end
				end
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!483O00028O00026O00144003093O004E6577536C69646572030A3O0053702O6564204861636B03233O005468697320736C696465722061646A75737473207468652073702O6564206861636B2E026O006940026O00304003093O004A756D70204861636B03283O005468697320736C696465722061646A7573747320746865206A756D7020706F776572206861636B2E025O00408F40026O00494003063O004E65775461622O033O004D5653030A3O004E657753656374696F6E031D3O004D75726465726572732056532053686572692O6673205363726970747303093O004E657742752O746F6E030A3O004D56532053637269707403253O004D75726465726572732056532053686572692O6673207363726970742E20286C6567697429026O001840026O00F03F027O004003093O004A756D70506F77657203043O0067616D65030A3O004765745365727669636503103O0055736572496E7075745365727669636503093O0057616C6B53702O656403093O0043686172616374657203083O0048756D616E6F6964026O00084003043O004578697403133O0045786974732066726F6D205472696D65202D53026O001040030E3O00496E66696E697465205969656C6403273O0046452041646D696E20636F2O6D616E647320666F7220612O6C20726F626C6F782067616D65732E030A3O00546F2O676C6520455350030B3O00546F2O676C65204553502E030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503083O005472696D65202D5303043O005465787403423O0053752O63657366752O6C7920696E6A6563746564210A446576656C6F7065642062793A204D657472696373656374204465762026206D75746F63616E5F626162613103153O005072652O73205A20666F7220746F2O676C65205549030C3O004D5653205363726970742032032A3O004D75726465726572732056532053686572692O667320736372697074203220286B692O6C20612O6C292E030A3O00546F2O676C6520504B4E03203O00546F2O676C6520506C61796572204B692O6C204E6F74696669636174696F6E2E03133O00546F2O676C652054656C65706F72742028432903433O005768656E206163746976617465642C207072652O73696E6720432077692O6C2074656C65706F727420746F2074686520656E656D7920706C6179657227732062617365026O001C4003423O009O2D9O2D9O2D2D20434F4E54524F4C53209O2D9O2D9O2D2D03083O004E65774C6162656C030C3O005A3A20546F2O676C6520554903063O00506C6179657203183O0052657365742053702O65642026204A756D7020506F77657203253O00546869732062752O746F6E2072657365742073702O65642026206A756D7020706F7765722E030A3O006C6F6164737472696E6703073O00482O747047657403463O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F436F64652D4D617374657231322F5472696D652D532D54502F6D61696E2F74702E6C756103483O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F436F64652D4D617374657231322F5472696D652D532D4553502F6D61696E2F6573702E6C756103483O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F436F64652D4D617374657231322F5472696D652D532D504B4E2F6D61696E2F706B6E2E6C756103053O007072696E74034C3O005472696D65202D533A2053752O63657366752O6C7920696E6A65637465642120446576656C6F7065642062793A204D657472696373656374204465762026206D75746F63616E5F626162613103043O004D61696E03073O00506C6179657273030B3O004C6F63616C506C6179657203533O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F436F64652D4D617374657231322F7472696D652D75692D6C69622F6D61696E2F7472696D652D6C6962726172792E6C756103093O004372656174654C6962030A3O00426C2O6F645468656D65030A3O00496E707574426567616E03073O00436F2O6E6563740011012O00122E3O00014O0018000100103O0026153O0022000100020004033O0022000100202B00110004000300122E001300043O00122E001400053O00122E001500063O00122E001600073O00060C00173O000100012O00233O00064O001000110017000100202O00110004000300122O001300083O00122O001400093O00122O0015000A3O00122O0016000B3O00060C00170001000100012O00233O00064O000100110017000100202O00110002000C00122O0013000D6O0011001300024O000300113O00202O00110003000E00122O0013000F6O0011001300024O000400113O00202O00110004001000122E001300113O00122E001400123O000219001500024O000D00110015000100122E3O00133O0026153O003A000100140004033O003A000100122E001100013O0026150011002A000100150004033O002A0001002012000A0006001600122E3O00153O0004033O003A000100261500110033000100140004033O00330001001232001200173O00201C00120012001800122O001400196O0012001400024O000800123O00202O00090006001A00122O001100153O00261500110025000100010004033O0025000100201200120005001B00201200060012001C2O002500075O00122E001100143O0004033O002500010026153O00710001001D0004033O0071000100122E001100013O0026150011004B000100150004033O004B000100202B00120004001000122E0014001E3O00122E0015001F3O00060C00160003000100052O00233O00014O00233O00074O00233O000E4O00233O000B4O00233O000C4O000D00120016000100122E3O00203O0004033O00710001000E0800140059000100110004033O0059000100202B00120004001000122E001400213O00122E001500223O000219001600044O000D00120016000100202B00120004001000122E001400233O00122E001500243O00060C00160005000100012O00233O000B4O000D00120016000100122E001100153O0026150011003D000100010004033O003D0001001232001200173O00200F00120012001800122O001400256O00120014000200202O00120012002600122O001400276O00153O000200302O00150028002900302O0015002A002B4O00120015000100122O001200173O00202B00120012001800121D001400256O00120014000200202O00120012002600122O001400276O00153O000200302O00150028002900302O0015002A002C4O00120015000100122O001100143O00044O003D00010026153O0094000100130004033O0094000100122E001100013O000E0800010082000100110004033O0082000100202B00120004001000122E0014002D3O00122E0015002E3O000219001600064O000D00120016000100202B00120004001000122E0014002F3O00122E001500303O00060C00160007000100012O00233O000C4O000D00120016000100122E001100143O0026150011008C000100140004033O008C000100202B00120004001000122E001400313O00122E001500323O00060C00160008000100012O00233O000E4O000D0012001600012O0018000F000F3O00122E001100153O00261500110074000100150004033O0074000100060C000F0009000100022O00233O00014O00233O00073O00122E3O00333O0004033O009400010004033O007400010026153O00AE000100200004033O00AE000100202B00110003000E00121B001300346O0011001300024O000400113O00202O00110004003500122O001300366O00110013000100202O00110002000C00122O001300376O0011001300024O000300113O00202B00110003000E001214001300376O0011001300024O000400113O00202O00110004001000122O001300383O00122O001400393O00060C0015000A000100032O00233O00064O00233O00094O00233O000A4O000D00110015000100122E3O00023O0026153O00D8000100150004033O00D8000100122E001100013O002615001100BD000100140004033O00BD00010012320012003A3O00120B001300173O00202O00130013003B00122O0015003C6O001300156O00123O00024O0012000100024O000D00126O000E5O00122O001100153O002615001100D0000100010004033O00D000010012320012003A3O001216001300173O00202O00130013003B00122O0015003D6O001300156O00123O00024O0012000100024O000B00123O00122O0012003A3O00122O001300173O00202O00130013003B00122E0015003E4O002C001300156O00123O00024O0012000100024O000C00123O00122O001100143O002615001100B1000100150004033O00B100010012320012003F3O00122E001300404O000900120002000100122E3O001D3O0004033O00D800010004033O00B100010026153O00FE000100010004033O00FE000100122E001100013O002615001100E6000100140004033O00E6000100202B00120002000C001207001400416O0012001400024O000300123O00202O00120003000E00122O001400416O0012001400024O000400123O00122O001100153O002615001100ED000100150004033O00ED0001001232001200173O00201200120012004200201200050012004300122E3O00143O0004033O00FE0001002615001100DB000100010004033O00DB00010012320012003A3O001222001300173O00202O00130013003B00122O001500446O001300156O00123O00024O0012000100024O000100123O00202O00120001004500122O001300293O00122O001400464O000E0012001400022O0023000200123O00122E001100143O0004033O00DB00010026153O0002000100330004033O000200012O0018001000103O00060C0010000B000100032O00233O000E4O00233O000D4O00233O00073O00203000110008004700202O0011001100484O001300106O00110013000100202O00110008004700202O0011001100484O0013000F6O00110013000100044O000F2O010004033O000200012O001F8O00263O00013O000C3O00013O0003093O0057616C6B53702O656401034O003500015O001002000100014O00263O00017O00013O0003093O004A756D70506F77657201034O003500015O001002000100014O00263O00017O00083O00028O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403493O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F4D72706F7063617466726F6D62757067652F46722O65437073766972732F6D61696E2F4D762O7303053O007072696E7403333O005472696D65202D533A204D5653205363726970742073752O63657366752O6C7920737461727465642120506C6163652049443A03073O00506C616365496400183O00122E3O00014O0018000100013O0026153O0002000100010004033O0002000100122E000100013O00261500010005000100010004033O00050001001232000200023O001220000300033O00202O00030003000400122O000500056O000300056O00023O00024O00020001000100122O000200063O00122O000300073O00122O000400033O00202O0004000400084O00020004000100044O001700010004033O000500010004033O001700010004033O000200012O00263O00017O000A3O00028O00027O004003063O0048696465554903053O007072696E74031D3O005472696D65202D533A2045786974206D61646520506C6163652049443A03043O0067616D6503073O00506C6163654964026O00F03F030A3O0044697361626C65455350030A3O0064697361626C65504B4E001E3O00122E3O00013O000E080002000C00013O0004033O000C00012O003500015O00200A0001000100034O00010002000100122O000100043O00122O000200053O00122O000300063O00202O0003000300074O00010003000100044O001D00010026153O0013000100010004033O001300012O0025000100014O0011000100014O002500016O0011000100023O00122E3O00083O000E080008000100013O0004033O000100012O0035000100033O00202A0001000100094O0001000200014O000100043O00202O00010001000A4O00010002000100124O00023O00044O000100012O00263O00017O00083O00028O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F4564676549592F696E66696E6974657969656C642F6D61737465722F736F7572636503053O007072696E7403373O005472696D65202D533A20496E66696E697465207969656C642073752O63657366752O6C7920737461727465642120506C6163652049443A03073O00506C616365496400183O00122E3O00014O0018000100013O0026153O0002000100010004033O0002000100122E000100013O00261500010005000100010004033O00050001001232000200023O001220000300033O00202O00030003000400122O000500056O000300056O00023O00024O00020001000100122O000200063O00122O000300073O00122O000400033O00202O0004000400084O00020004000100044O001700010004033O000500010004033O001700010004033O000200012O00263O00017O00053O0003093O00746F2O676C6545535003053O007072696E7403203O005472696D65202D533A2045535020546F2O676C65642120506C6163652049443A03043O0067616D6503073O00506C616365496400094O001A7O00206O00016O0002000100124O00023O00122O000100033O00122O000200043O00202O0002000200056O000200016O00017O00083O00028O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O7470476574034D3O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F44656E693231302F6D757264657273762O7368652O726966736475656C732F6D61696E2F7275627968756203053O007072696E7403333O005472696D65202D533A204D5653205363726970742073752O63657366752O6C7920737461727465642120506C6163652049443A03073O00506C616365496400193O00122E3O00014O0018000100013O000E080001000200013O0004033O0002000100122E000100013O000E0800010005000100010004033O00050001001232000200023O001233000300033O00202O00030003000400122O000500056O000600016O000300066O00023O00024O00020001000100122O000200063O00122O000300073O00122O000400033O00202O0004000400084O00020004000100044O001800010004033O000500010004033O001800010004033O000200012O00263O00017O00063O00028O0003093O00746F2O676C65504B4E03053O007072696E7403203O005472696D65202D533A20504B4E20546F2O676C65642120506C6163652049443A03043O0067616D6503073O00506C6163654964000E3O00122E3O00013O0026153O0001000100010004033O000100012O003500015O00200A0001000100024O00010002000100122O000100033O00122O000200043O00122O000300053O00202O0003000300064O00010003000100044O000D00010004033O000100012O00263O00017O000B3O00028O0003043O0067616D65030A3O0047657453657276696365030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503083O005472696D65202D5303043O0054657874030B3O00545020456E61626C656421030C3O0054502044697361626C65642100273O00122E3O00014O0018000100013O000E080001000200013O0004033O0002000100122E000100013O00261500010005000100010004033O000500012O003500026O0028000200024O001100026O003500025O0006240002001800013O0004033O00180001001232000200023O00200500020002000300122O000400046O00020004000200202O00020002000500122O000400066O00053O000200302O00050007000800302O00050009000A4O00020005000100044O00260001001232000200023O00200500020002000300122O000400046O00020004000200202O00020002000500122O000400066O00053O000200302O00050007000800302O00050009000B4O00020005000100044O002600010004033O000500010004033O002600010004033O000200012O00263O00017O00083O00028O00026O00F03F030D3O0055736572496E7075745479706503043O00456E756D03083O004B6579626F61726403073O004B6579436F646503013O005A03083O00546F2O676C655549021F3O00122E000200013O00261500020013000100020004033O0013000100201200033O0003001232000400043O0020120004000400030020120004000400050006170003001E000100040004033O001E000100201200033O0006001232000400043O0020120004000400060020120004000400070006170003001E000100040004033O001E00012O003500035O00202B0003000300082O00090003000200010004033O001E000100261500020001000100010004033O000100010006240001001800013O0004033O001800012O00263O00014O0035000300013O0006240003001C00013O0004033O001C00012O00263O00013O00122E000200023O0004033O000100012O00263O00017O00103O00028O00026O00F03F03053O007072696E7403373O005472696D65202D533A2053702O65642026204A756D7020506F776572206861766520622O656E2072657365742120506C6163652049443A03043O0067616D6503073O00506C6163654964030A3O0047657453657276696365030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503083O005472696D65202D5303043O005465787403233O0053702O65642026204A756D7020506F776572206861766520622O656E2072657365742103093O0057616C6B53702O656403093O004A756D70506F77657200243O00122E3O00014O0018000100013O0026153O0002000100010004033O0002000100122E000100013O00261500010017000100020004033O00170001001232000200033O00122D000300043O00122O000400053O00202O0004000400064O00020004000100122O000200053O00202O00020002000700122O000400086O00020004000200202O00020002000900122O0004000A6O00053O000200302O0005000B000C00302O0005000D000E4O00020005000100044O0023000100261500010005000100010004033O000500012O003500026O0031000300013O00102O0002000F00034O00028O000300023O00102O00020010000300122O000100023O00044O000500010004033O002300010004033O000200012O00263O00017O00083O00028O00026O00F03F030D3O0055736572496E7075745479706503043O00456E756D03083O004B6579626F61726403073O004B6579436F646503013O004303123O00636865636B416E644D6F7665506C6179657202233O00122E000200013O00261500020017000100020004033O001700012O003500035O00063400030007000100010004033O000700012O00263O00013O00201200033O0003001232000400043O00201200040004000300201200040004000500061700030022000100040004033O0022000100201200033O0006001232000400043O00201200040004000600201200040004000700061700030022000100040004033O002200012O0035000300013O00202B0003000300082O00090003000200010004033O00220001000E0800010001000100020004033O000100010006240001001C00013O0004033O001C00012O00263O00014O0035000300023O0006240003002000013O0004033O002000012O00263O00013O00122E000200023O0004033O000100012O00263O00017O00", GetFEnv(), ...);
