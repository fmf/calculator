{
	 data -- routines for calculator program
	 version 1.0, August 4th, 2012
	
	 Copyright (C) 2012 Florea Marius Florin
	
	 This software is provided 'as-is', without any express or implied
	 warranty.  In no event will the authors be held liable for any damages
	 arising from the use of this software.
	
	 Permission is granted to anyone to use this software for any purpose,
	 including commercial applications, and to alter it and redistribute it
	 freely, subject to the following restrictions:
	
			1. The origin of this software must not be misrepresented; you must not
				claim that you wrote the original software. If you use this software
				in a product, an acknowledgment in the product documentation would be
				appreciated but is not required.
			2. Altered source versions must be plainly marked as such, and must not be
				misrepresented as being the original software.
			3. This notice may not be removed or altered from any source distribution.
	
	Florea Marius Florin, florea.fmf@gmail.com
}

(* This unit contains the actual calculator and the string 
* parsing routines. *)

{$mode objfpc}
{$calling cdecl}
{$h+}

unit data;


interface



	const
		(* the limit for stack, and the input calculator accepts *)
		LIMIT = 500;


	var
		(*  signals the gui if there were errors during computation
		 * so it can take proper action
		 *
		 * 1 : stack is full;
		 * 2 : stack is empty;
		 * 3 : division by 0;
		 * 4 : negative square root  --> imaginary numbers, this program doesn't deal with them
		 * 5 : float operands for modulus
		 * 6 : 90 deg tangent --> undefined
		 * 7 : 0 deg cotangent --> undefined
		 * 8 : log(0) --> undefined
		 * 9 : log(-x) --> imaginary numbers
		 * 10: ln(0) --> undefined
		 * 11: ln(-x) --> imaginary numbers
		 * 12: invalid chars
		 * 13: module gui: memory full
		 * 14: malformed expression *)
		ERROR: byte;
		(* tells the program how to evaluate the given string
		* 1 = infix
		* 2 = postfix; *)
		EVAL: byte;
		(* tells the program in what mode the program is (dafuq?)
		* to call the appropiate string parsing routines 
		* 1 = basic
		* 2 = advanced; *)
		MODE: byte;
		(* the number of decimals a result should be computed *)
		DECIMAL_PLACES: byte;		// values [0..7]
	
	
	(* the function that takes the string and returns the result  *)
	function compute_format(s: string): string;
	(* basic input verifier, only checks for invalid characters *)
	function verify_input(s: string): boolean;
	
	
	
implementation
	
	
	
	uses
		sysutils, math;	
		
	const
		pi = 3.141592653;
		e = 2.718281828;
	
	
	var
		// the stack on which the computations are made
		postfixStack: array[1..LIMIT] of real;
		// infixPos: current position in original infix string
		//				need it when searching string for negative numbers 
		// postifxSp, infixSp: postfix/infix stack position
		postfixSp, infixSp, infixPos: integer;
		// the stack that holds operators when transforming from
		//infix to postifx
		infixStack: array[1..LIMIT] of string;
	
	
	(* pushes element on the postfix stack *)
	procedure postfix_push(x: real);
		begin
			if (postfixSp < LIMIT) then begin
				inc(postfixSp);
				postfixStack[postfixSp]:= x;
			end else
				ERROR:= 1;
		end;
	
	
	(* pops element from postifx stack *)
	function postfix_pop(): real;
		begin
			if (postfixSp > 0) then begin
				result:= postfixStack[postfixSp];
				dec(postfixSp);
			end else
				ERROR:= 2;
		end;
	
	
	(* push operand on infix stack *)
	procedure infix_push(x: string);
		begin
			if (infixSp < LIMIT) then begin
				inc(infixSp);
				infixStack[infixSp]:= x;
			end else
				ERROR:= 1;
		end;
	
	
	(* pop operand from infix stack *)
	function infix_pop(): string;
		begin
			if (infixSp > 0) then begin
				result:= infixStack[infixSp];
				dec(infixSp);
			end else
				ERROR:= 2;
		end;
	
	
	(* gets the next operand from the input string
	* it destroys the string when finished, make sure to send
	* a copy of the string *)
	function postfix_get_operand(var s: string): string;
		var
			i: integer;
			d: string;   // dummy
		begin
			d:= ''; i:= 1;
			if (pos(s[i], '+-*/#pe^;%!@$&|\ ') > 0) then
				if (s[i]= '-') and (s[i+1]= ' ') or (pos(s[i], '+*/#pe^;%!@$&|\ ') > 0) then begin
					result:= s[i];
					delete(s, 1, 2);
				end
			else begin
				while (pos(s[i], '+*/#pe^;%!@$&|\ ') = 0) do begin
					d:=concat(d, s[i]);
					inc(i);
				end;
				delete(s, 1, i);
				result:= d;
			end else begin
				while (pos(s[i], '+-*/#pe^;%!@$&|\ ') = 0) do begin
					d:=concat(d, s[i]);
					inc(i);
				end;
				delete(s, 1, i);
				result:= d;
			end;
		end;
		
		
	(* gets the next element (operand/operator) from the input
	* string, formated as infix notation *)
	function infix_get_operand(var s: string; sorig: string): string;
		var
			i: integer;
			d: string;   // dummy
		begin
			d:= ''; i:= 1;
			if (pos(s[i], '+-*/()#pe^;!@$&|\%') > 0) then
				if (s[i]= '-') and (sorig[infixPos] <> '(') or (pos(s[i], '+*/()#pe^;!@$&|\%') > 0) then begin
					result:= s[i];
					delete(s, 1, 1);
				end
			else begin
				while (pos(s[i], '+*/()#pe^;!@$&|\%') = 0) do begin
					d:=concat(d, s[i]);
					inc(i);
				end;
				delete(s, 1, i);
				result:= d;
				infix_pop();
			end else begin
				while (pos(s[i], '+-*/()#pe^;!@$&|\%') = 0) do begin
					d:=concat(d, s[i]);
					inc(i);
				end;
				delete(s, 1, i-1);
				result:= d;
			end;
		end;
	
	
	(* the reverse polish notation calculator
	*  
	* sign meanings:
	* 		pi:      p  | done
	* 		euler nr:e  | done
	* 		power:   ^  | done
	* 		sin():   !  | done
	* 		cos():   @  | done
	* 		tan():   $  | done
	* 		cotan(): &  | done
	* 		log():   |  | done
	* 		ln():    \  | done
	* 		sqrt():  ;   | done
	* 		modulus: %    | done  *)
	function postfix_calculator(s: string): real;
		var
			ds: string;  // dummy
			dr: real;    // dummy
			di: longint; // dummy
			err: integer;
		begin
			postfixSp:= 0;
			s:= concat(s, ' #');	// the "#" signals the end of string
			while (length(s) > 0) and (ERROR = 0) do begin
				ds:= postfix_get_operand(s);
				case ds of
					'p' : postfix_push(pi);
					'e' : postfix_push(e);
					'^' : begin
							dr:= postfix_pop();
							postfix_push(power(postfix_pop(), dr));
						  end;
					';' : begin
							dr:= postfix_pop();
							if (abs(dr-0.0) < 0.000000001) then 
								ERROR:= 4
							else
								postfix_push(sqrt(dr));
						  end;
					'%' : begin
							dr:= postfix_pop();
							di:= round(dr);
							if (abs(frac(dr)-0.0) > 0.000000001) then
								ERROR:= 5
							else begin
								dr:= postfix_pop();
								if (abs(frac(dr)-0.0) > 0.000000001) then
									ERROR:= 5
								else
									postfix_push(round(dr) mod di);
							end;
						  end;
					'!' : postfix_push(sin(degToRad(postfix_pop())));
					'@' : postfix_push(cos(degToRad(postfix_pop())));
					'$' : begin
							dr:= postfix_pop();
							if (abs(dr-90.0) < 0.000000001) then
								ERROR:= 6
							else
								postfix_push(tan(degToRad(dr)));
						  end;
					'&' : begin
							dr:= postfix_pop();
							if (abs(dr-0.0) < 0.000000001) then
								ERROR:= 7
							else
								postfix_push(cotan(degToRad(dr)));
						  end;
					'|' : begin
							dr:= postfix_pop();
							if (abs(dr-0.0) < 0.000000001) then
								ERROR:= 8
							else if (abs(dr) <> dr) then
								ERROR:= 9
							else
								postfix_push(log10(dr));
						  end;
					'\' : begin
							dr:= postfix_pop();
							if (abs(dr-0.0) < 0.000000001) then
								ERROR:= 10
							else if (abs(dr) <> dr) then
								ERROR:= 11
							else
								postfix_push(ln(dr));
						  end;
					'*' : postfix_push(postfix_pop() * postfix_pop());
					'+' : postfix_push(postfix_pop() + postfix_pop());
					'/' : begin
							dr:= postfix_pop();
							if (abs(dr-0.0) < 0.000000001) then
								ERROR:= 3
							else
								postfix_push(postfix_pop() / dr);
						  end;
					'-' : begin
							dr:= postfix_pop();
							postfix_push(postfix_pop() - dr);
						  end;
					'#' : result:= postfixStack[1];
				else begin
					err:= 0;
					val(ds, dr, err);
					if (err = 0) then
						postfix_push(dr)
					else
						ERROR:= 14;
				end;
				end;
			end;
			dec(postfixSp);
		end;
	
	
	(* converts the infix string to a postifx representation,
	* the one understood by the calculator
	* 
	* sign meanings:
	* 		pi:      p  | done
	* 		euler nr:e  | done
	* 		power:   ^  | done
	* 		sin():   !  | done
	* 		cos():   @  | done
	* 		tan():   $  | done
	* 		cotan(): &  | done
	* 		log():   |  | done
	* 		ln():    \  | done
	* 		sqrt():  ;   | done
	* 		modulus: %    | done *)
	function infix_to_postfix(sorig: string): string;
		var
			s, res, ds, ds2: string;
		begin
			s:= concat(sorig, '#');    // "#" marks end of string
			res:= ''; infixPos:= 0;
			while (length(s) > 0) do begin
				ds:= infix_get_operand(s, sorig);
				infixPos:= infixPos + length(ds);
				case ds of
					'p', 'e' : res:=concat(res, ds, ' ');
					'(' : infix_push(ds);
					')' : begin
							while ((infixSp > 0) and (infixStack[infixSp] <> '(')) do begin
								ds2:= infix_pop();
								res:= concat(res, ds2, ' ');
							end;
							if (infixStack[infixSp] = '(') then
								infix_pop();
						  end;
					'^' : begin
							if (infixSp = 0) then
								infix_push(ds)
							else begin
								while ((infixSp > 0) and (infixStack[infixSp] = '(')) do begin
									ds2:= infix_pop();
									res:= concat(res, ds2, ' ');
								end;
								infix_push(ds);
							end;
						  end;
					';', '!', '@', '$', '&', '|', '\': 
						  begin
							if (infixSp = 0) then
								infix_push(ds)
							else begin
								while ((infixSp > 0) and ((infixStack[infixSp] = ';') or (infixStack[infixSp] = '!')
										or (infixStack[infixSp] = '@') or (infixStack[infixSp] = '$')
										or (infixStack[infixSp] = '&') or (infixStack[infixSp] = '|')
										or (infixStack[infixSp] = '\'))) do begin
									ds2:= infix_pop();
									res:= concat(res, ds2, ' ');
								end;
								infix_push(ds);
							end;
						  end;
					'*', '/', '%' : begin
							if (infixSp = 0) then
								infix_push(ds)
							else begin
									while ((infixSp > 0) and ((infixStack[infixSp] = '*') or (infixStack[infixSp] = '/')
											or (infixStack[infixSp] = '^') or (infixStack[infixSp] = ';')
											or (infixStack[infixSp] = '!') or (infixStack[infixSp] = '@')
											or (infixStack[infixSp] = '$') or (infixStack[infixSp] = '&')
											or (infixStack[infixSp] = '|') or (infixStack[infixSp] = '\')
											or (infixStack[infixSp] = '%'))) do begin
										ds2:= infix_pop();
										res:= concat(res, ds2, ' ');
									end;
								infix_push(ds);
							end;
						  end;
					'+', '-' : begin
							if (infixSp = 0) then
								infix_push(ds)
							else begin
								while ((infixSp > 0) and (infixStack[infixSp] <> '(')) do begin
									ds2:= infix_pop();
									res:= concat(res, ds2, ' ');
								end;
								infix_push(ds);
							end;
						  end;
					'#' : begin
							if (infixSp > 0) then
								while (infixSp > 0) do begin
									ds2:= infix_pop();
									res:= concat(res, ds2, ' ');
								end;
							delete(res, length(res), 1);
							result:= res;
						end;
				else
					res:= concat(res, ds, ' ');
				end;
			end;
		end;
	
	
	(* replaces unicode chars with symbols understood by algorithm
	* and funcs names by symbols *)
	procedure transform_input(var s: string);
		var
			// dummy vars
			di: integer;
			dsDivizor, dsPi, dsSqrt, dsMult: string;
		begin
			dsDivizor:= string(UTF8String(#$C3#$B7));
			while (pos(dsDivizor, s) > 0) do begin
				di:= pos(dsDivizor, s);
				s[di]:= '/';
				delete(s, di+1, 1);
			end;
			dsMult:= string(UTF8String(#$C3#$97));
			while (pos(dsMult, s) > 0) do begin
				di:= pos(dsMult, s);
				s[di]:= '*';
				delete(s, di+1, 1);
			end;
			
			if (MODE=2) then begin
				dsPi:= string(UTF8String(#$CF#$80));
				while (pos(dsPi, s) > 0) do begin
					di:= pos(dsPi, s);
					s[di]:= 'p';	// pi sign
					delete(s, di+1, 1);
				end;
				dsSqrt:= string(UTF8String(#$E2#$88#$9A));
				while (pos(dsSqrt, s) > 0) do begin
					di:= pos(dsSqrt, s);
					s[di]:= ';';	// sqrt sign
					delete(s, di+1, 2);
				end;
				
				while (pos('sin', s) > 0) do begin
					di:= pos('sin', s);
					s[di]:= '!';
					delete(s, di+1, 2);
				end;
				while (pos('cos', s) > 0) do begin
					di:= pos('cos', s);
					s[di]:= '@';
					delete(s, di+1, 2);
				end;
				// cotan must be above tan, otherwise it breaks
				while (pos('cotan', s) > 0) do begin
					di:= pos('cotan', s);
					s[di]:= '&';
					delete(s, di+1, 4);
				end;
				while (pos('tan', s) > 0) do begin
					di:= pos('tan', s);
					s[di]:= '$';
					delete(s, di+1, 2);
				end;
				while (pos('log', s) > 0) do begin
					di:= pos('log', s);
					s[di]:= '|';
					delete(s, di+1, 2);
				end;
				while (pos('ln', s) > 0) do begin
					di:= pos('ln', s);
					s[di]:= '\';
					delete(s, di+1, 1);
				end;
				while (pos('sqrt', s) > 0) do begin
					di:= pos('sqrt', s);
					s[di]:= ';';
					delete(s, di+1, 3);
				end;
				while (pos('mod', s) > 0) do begin
					di:= pos('mod', s);
					s[di]:= '%';
					delete(s, di+1, 2);
				end;
				while (pos('pi', s) > 0) do begin
					di:= pos('pi', s);
					s[di]:= 'p';
					delete(s, di+1, 1);
				end;
				
				// re-check string for any unwanted chars
				for di:=1 to length(s) do
					if (pos(s[di], '`qwrtyuio[]asdfghjkl''zxcvbnm,~#_=QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?') <> 0) then
						ERROR:= 12;
			end;
		end;
	
	
	(* glue function that puts together the infix transformation
	* and the resulting postfix evaluation *)
	function compute(s: string): real;
		var
			d: string;
		begin
			transform_input(s);
			if (ERROR = 0) then
				if (MODE = 1) then
					if (EVAL = 1) then begin
						d:= infix_to_postfix(s);
						result:= postfix_calculator(d);
					end else 
						result:= postfix_calculator(s)
				else
					if (EVAL = 1) then begin
						d:= infix_to_postfix(s);
						result:= postfix_calculator(d)
					end else
						result:= postfix_calculator(s)
			else
				result:= 0.00;
		end;
	
	(* returns the result to DECIMAL_PLACES decimal places (mind = blown)
	* if it has or no decimals if doesn't have
	* and strips the zeros without value *)
	function compute_format(s: string): string;
		var
			x: real;
			i: byte;
			ds: string;
		begin
			x:= compute(s);
			if (abs(x-0.0) < 0.000000001) then
				result:= floatToStrF(x, ffFixed, 0, 0)
			else begin
				ds:= floatToStrF(x, ffFixed, 0, DECIMAL_PLACES);
				i:= length(ds);
				while (ds[i] = '0') do begin
					delete(ds, i, 1);
					dec(i);
				end;
				if (ds[i] = '.') then
					delete(ds, i, 1);
				result:= ds;
			end;
		end;
	
	
	(* basic input verifier, checks for unwanted characters
	* doesn't verifies if the input is a valid expression *)
	function verify_input(s: string): boolean;
		var
			d: boolean;
			i: integer;
		begin
			d:= true;
			ERROR:= 0;
			if (MODE = 1) then
				case EVAL of
				1 : begin
						for i:=1 to length(s) do
							if (pos(s[i], '`qwertyuiop[]\asdfghjkl;''zxcvbnm,~!@#$%^&_=QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>? ') <> 0) then begin
								d:= false;
								break;
							end;
					end;
				2 : begin
						for i:=1 to length(s) do
							if (pos(s[i], '`qwertyuiop[]\asdfghjkl;''zxcvbnm,~!@#$%^&_=QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?()') <> 0) then begin
								d:= false;
								break;
							end;
					end;
				end
			else
				case EVAL of
				1 : begin
						for i:=1 to length(s) do
							if (pos(s[i], '`wyu[]fhjk;''zxvb,~#_=QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>? ') <> 0) then begin
								d:= false;
								break;
							end;
					end;
				2 : begin
						for i:=1 to length(s) do
							if (pos(s[i], '`wyu[]fhjk;''zxvb,~#_=QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?()') <> 0) then begin
								d:= false;
								break;
							end;
					end;
				end;
			result:= d;
		end;
	
	
end.