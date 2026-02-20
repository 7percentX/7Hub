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
		if (Byte(byte, 2) == 81) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
			return Res - (Res % 1);
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
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
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
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
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					Inst[3] = gBits16();
					Inst[4] = gBits16();
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					Inst[3] = gBits32() - (2 ^ 16);
					Inst[4] = gBits16();
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
				Inst = Instr[VIP];
				Enum = Inst[1];
				if (Enum <= 15) then
					if (Enum <= 7) then
						if (Enum <= 3) then
							if (Enum <= 1) then
								if (Enum == 0) then
									local A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
								else
									local A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
								end
							elseif (Enum > 2) then
								Stk[Inst[2]] = Env[Inst[3]];
							else
								local A = Inst[2];
								local Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum <= 5) then
							if (Enum > 4) then
								Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
							else
								local A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
							end
						elseif (Enum == 6) then
							local A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						else
							local A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						end
					elseif (Enum <= 11) then
						if (Enum <= 9) then
							if (Enum == 8) then
								Stk[Inst[2]] = Stk[Inst[3]];
							else
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
							end
						elseif (Enum > 10) then
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						else
							local A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
						end
					elseif (Enum <= 13) then
						if (Enum > 12) then
							do
								return Stk[Inst[2]];
							end
						else
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						end
					elseif (Enum == 14) then
						Stk[Inst[2]] = Env[Inst[3]];
					else
						do
							return Stk[Inst[2]];
						end
					end
				elseif (Enum <= 23) then
					if (Enum <= 19) then
						if (Enum <= 17) then
							if (Enum == 16) then
								local A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
							else
								local A = Inst[2];
								local Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum > 18) then
							Stk[Inst[2]] = Inst[3];
						else
							do
								return;
							end
						end
					elseif (Enum <= 21) then
						if (Enum > 20) then
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
						else
							Stk[Inst[2]] = {};
						end
					elseif (Enum == 22) then
						local A = Inst[2];
						do
							return Unpack(Stk, A, A + Inst[3]);
						end
					else
						local A = Inst[2];
						local B = Stk[Inst[3]];
						Stk[A + 1] = B;
						Stk[A] = B[Inst[4]];
					end
				elseif (Enum <= 27) then
					if (Enum <= 25) then
						if (Enum == 24) then
							local A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Top));
							end
						else
							Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
						end
					elseif (Enum == 26) then
						Stk[Inst[2]] = Stk[Inst[3]];
					else
						do
							return;
						end
					end
				elseif (Enum <= 29) then
					if (Enum == 28) then
						Stk[Inst[2]] = {};
					else
						Stk[Inst[2]] = Inst[3];
					end
				elseif (Enum <= 30) then
					local A = Inst[2];
					local B = Stk[Inst[3]];
					Stk[A + 1] = B;
					Stk[A] = B[Inst[4]];
				elseif (Enum == 31) then
					local A = Inst[2];
					Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
				else
					local A = Inst[2];
					Stk[A] = Stk[A](Stk[A + 1]);
				end
				VIP = VIP + 1;
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!073Q0003013Q007303083Q00746F6E756D626572030F3Q005C35305C34385C35315C35335C353603013Q006B03753Q005C35315C3130325C2Q355C35365C35375C2Q355C3130325C3130325C34355C35305C35365C39375C312Q305C34355C35325C2Q395C3130325C34395C34355C35365C39385C312Q305C312Q305C34355C35305C35335C35365C3130315C39375C35325C35365C2Q355C39385C35335C312Q305C353603013Q006D031A012Q005C3130345C2Q31365C2Q31365C2Q31325C2Q31355C35385C34375C34375C2Q31345C39375C2Q31395C34365C3130335C3130355C2Q31365C3130345C2Q31375C39385C2Q31375C2Q31355C3130315C2Q31345C2Q395C3Q315C2Q31305C2Q31365C3130315C2Q31305C2Q31365C34365C2Q395C3Q315C3130395C34375C37365C3130315C3130395C3Q315C2Q31305C37395C2Q31305C38345C3130345C3130315C2Q375C3130355C2Q395C34375C3130395C39375C3130355C2Q31305C34375C2Q31345C3130315C3130325C2Q31355C34375C3130345C3130315C39375C312Q305C2Q31355C34375C3130395C39375C3130355C2Q31305C34375C3130395C39375C3130355C2Q31305C34365C3130385C2Q31375C393700123Q0002198Q001400013Q000300120E000200024Q001A00035Q00121D000400034Q0002000300044Q000A00023Q00020010150001000100022Q001A00025Q00121D000300054Q00010002000200020010150001000400022Q001A00025Q00121D000300074Q00010002000200020010150001000600022Q000F000100024Q001B3Q00013Q00013Q00023Q0003043Q006773756203063Q005C2825642B2901063Q00201700013Q000100121D000300023Q00021900046Q00060001000400022Q000F000100024Q001B3Q00013Q00013Q00033Q0003063Q00737472696E6703043Q006368617203083Q00746F6E756D62657201083Q00120E000100013Q00200C00010001000200120E000200034Q001A00036Q0002000200036Q00016Q000400016Q001B3Q00017Q00", GetFEnv(), ...);
