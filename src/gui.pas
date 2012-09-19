{
	 gui -- gui of calculator program
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

(* The unit that handles the program gui,
* creates the window, takes input, shows output... *)

{$calling cdecl}
{$mode objfpc}
{$h+}

unit gui;


interface
	
	
	(* takes care of almost everything in the program.
	* from preparing it to responding to user events *)
	procedure start();
	

implementation

	uses
		glib2, gdk2, gtk2, pango, data, xpm;
		
		
	type
		pGdkPixbuf = pointer;
		
		
	var
		entryBasic, entryAdv, basicWindow, advancedWindow,
			menuBasic, menuAdvanced,
			(* menu vars, need it when switching modes,
			* so the program displays the right mode as selected *)
			mbbasic, maadv,
			(* spin button for decimal places *)
			spinBtn: pGtkWidget;
			
		(* list: display the items in memory *)
		list: pGtkWidget;
		(* 1st element = the button
		* 2nd element = the label of the button *)
		listItems: array[1..8,1..2] of pGtkWidget;
		(* first element = position (eg: 1, 5, 7);
		* 2nd element = actual value of that row (eg: 65, 2*4...); *)
		listValues: array[1..8,1..2] of string;
		(* the position of the item selected by the user *)
		listSelected: integer;
	
		(* 1: visible
		* 2: hidden *)
		memoryStatus: byte;
		(* memory addition, for basic calc *)
		madd: string;
		
		(* the last infix string sent for evaluation
		* when the user presses return after the string
		* has been evaluated, original string will be shown *)
		infixStr: string;
		(* holds the result of the last infix string evaluation *)
		evalStr: string;
		
		(* tels if the user clicked inside the entry *)
		clicked: boolean;
		progIcon: pGdkPixbuf;
		
		(* *drum rolls* the input string *ta da* *)
		input: string;
		
		
	
	(* define gtk missing funcs *)
	{$ifdef unix}
		function gdk_pixbuf_new_from_xpm_data(data: ppgchar): pGdkPixbuf; external 'libgdk_pixbuf-2.0.so';
	{$endif}
	{$ifdef windows}
		function gdk_pixbuf_new_from_xpm_data(data: ppgchar): pGdkPixbuf; external 'libgdk_pixbuf-2.0-0.dll';
	{$endif}
	
	
	(* sets program defaults *)
	procedure set_defaults();
		begin
			MODE:= 1;   // basic
			EVAL:= 1;   // infix
			DECIMAL_PLACES:= 2;
			
			memoryStatus:= 2;  // hidden
			listSelected:= 0;
			clicked:= false;
			
			progIcon:= gdk_pixbuf_new_from_xpm_data(ppgchar(XPM_PROG_ICON));
		end;
	
	
	(* used to close the license, credits, decimal, error windows *)
	procedure destroy_child_window(qbutton: pGtkButton; window: pGtkWindow);
		begin
			gtk_widget_destroy(pGtkWidget(window));
		end;
	
	
	(* show hide the memory items *)
	procedure memory_show_hide(x: byte);
		begin
			if (x = 1) then begin
				gtk_widget_show_all(list);
				memoryStatus:= 1;
			 end else begin
				gtk_widget_hide(list);
				memoryStatus:= 2;
			end;
		end;
	
	
	(* change program mode
	* 1: basic; 2: advanced; *)
	procedure switch_mode(widget: pGtkWidget; data: pgpointer);
		begin	
			if (pchar(data) = '1') then begin
				gtk_widget_hide(advancedWindow);
				gtk_widget_show_all(basicWindow);
				gtk_check_menu_item_set_active(pGtkCheckMenuItem(mbbasic), true);
				MODE:= 1;
				clicked:= false;
			end else begin
				gtk_widget_hide(basicWindow);
				gtk_widget_show_all(advancedWindow);
				memory_show_hide(memoryStatus);
				gtk_check_menu_item_set_active(pGtkCheckMenuItem(maadv), true);
				MODE:= 2;
				clicked:= false;
			end;
		end;
	
	
	(* change program evaluation method
	* 1: infix; 2: postifx *)
	procedure switch_eval(widget: pGtkWidget; data: pgpointer);
		begin
			if (pchar(data) = '1') then begin
				EVAL:= 1;
				clicked:= false;
			end else begin
				EVAL:= 2;
				clicked:= false;
			end;
		end;
	
	
	procedure show_license();
		var
			window, vbox, button, label_, hbox: pGtkWidget;
		begin
			window:= gtk_window_new(gtk_window_toplevel);
			gtk_window_set_title(pGtkWindow(window), 'License');
			gtk_window_set_position(pGtkWindow(window), gtk_win_pos_center_on_parent);
			gtk_window_set_destroy_with_parent(pGtkWindow(window), true);
			gtk_window_set_resizable(pGtkWindow(window), false);
			if (MODE = 1) then
				gtk_window_set_transient_for(pGtkWindow(window), pGtkWindow(basicWindow))
			else
				gtk_window_set_transient_for(pGtkWindow(window), pGtkWindow(advancedWindow));
			g_signal_connect(window, 'destroy', g_callback(@gtk_widget_destroy), window);
			gtk_widget_realize(window);
			
			vbox:= gtk_vbox_new(false, 0);
			gtk_container_add(pGtkContainer(window), vbox);
			
			label_:= gtk_label_new('Calculator -- a calculator program '#10'version 1.0, '+
			'August 4, 2012'#10#10'Copyright (C) 2012 Florea Marius Florin'#10#10'This software is '+
			'provided ''as-is'', without any express or implied'#10'warranty.  In no event will the '+
			'authors be held liable for any damages'#10' arising from the use of this software.'+
			''#10#10'Permission is granted to anyone to use this software for any purpose,'#10''+
			'including commercial applications, and to alter it and redistribute it'#10'freely, '+
			'subject to the following restrictions:'#10#10#9'1. The origin of this software must '+
			'not be misrepresented; you must not'#10#9#9'claim that you wrote the original software. '+
			'If you use this software'#10#9#9'in a product, an acknowledgment in the product '+
			'documentation would be'#10#9#9'appreciated but is not required.'#10#9'2. Altered '+
			'source versions must be plainly marked as such, and must not be'#10#9#9'misrepresented '+
			'as being the original software.'#10#9'3. This notice may not be removed or altered '+
			'from any source distribution.'#10#10'Florea Marius Florin, florea.fmf@gmail.com');
			gtk_box_pack_start(pGtkBox(vbox), label_, false, false, 0);
		
			hbox:= gtk_hbox_new(false, 0);
			gtk_box_pack_start(pGtkBox(vbox), hbox, false, false, 0);
			
			button:= gtk_button_new_with_label('     Close     ');
			g_signal_connect(g_object(button), 'clicked', g_callback(@destroy_child_window),
								pgpointer(window));
			gtk_box_pack_end(pGtkBox(hbox), button, false, false, 0);
			
			gtk_widget_show_all(window);
		end;
		
		
	procedure show_credits();
		var
			window, vbox, hbox, button, label_, img: pGtkWidget;
			pixbuf: pGdkPixbuf;
		begin
			window:= gtk_window_new(gtk_window_toplevel);
			gtk_window_set_title(pGtkWindow(window), 'Credits');
			gtk_window_set_position(pGtkWindow(window), gtk_win_pos_center_on_parent);
			gtk_window_set_destroy_with_parent(pGtkWindow(window), true);
			gtk_window_set_resizable(pGtkWindow(window), false);
			if (MODE = 1) then
				gtk_window_set_transient_for(pGtkWindow(window), pGtkWindow(basicWindow))
			else
				gtk_window_set_transient_for(pGtkWindow(window), pGtkWindow(advancedWindow));
			g_signal_connect(window, 'destroy', g_callback(@gtk_widget_destroy), window);
			gtk_widget_realize(window);
			
			vbox:= gtk_vbox_new(false, 0);
			gtk_container_add(pGtkContainer(window), vbox);
			
			hbox:= gtk_hbox_new(false, 0);
			gtk_box_pack_start(pGtkBox(vbox), hbox, false, false, 0);
			
			label_:= gtk_label_new(#9'Developer: Florea Marius Florin'#10#10#9'Special thanks to:'+
			''#10#9#9'-FPC team: for building the compiler'#10#9#9'-Gtk+ team: for making the toolkit');
			gtk_box_pack_start(pGtkBox(hbox), label_, false, false, 0);
			
			pixbuf:= gdk_pixbuf_new_from_xpm_data(XPM_BADGER);
			img:= gtk_image_new_from_pixbuf(pixbuf);
			
			gtk_box_pack_start(pGtkBox(vbox), img, false, false, 5);
			
			hbox:= gtk_hbox_new(false, 0);
			gtk_box_pack_start(pGtkBox(vbox), hbox, false, false, 0);
			
			button:= gtk_button_new_with_label('     Close     ');
			g_signal_connect(g_object(button), 'clicked', g_callback(@destroy_child_window),
								pgpointer(window));
			gtk_box_pack_end(pGtkBox(hbox), button, false, false, 0);
			
			gtk_widget_show_all(window);
		end;
	
	
	(* returns the number of decimals to which to print the answer *)
	procedure get_decimals(widget: pGtkWidget; data: pgpointer);
		begin
			DECIMAL_PLACES:= gtk_spin_button_get_value_as_int(pGtkSpinButton(spinBtn));
		end;
	
	
	(* shows the window in which the user can change the number of
	* decimals the answer is printed *)
	procedure change_decimals();
		var
			window, label_, button, vbox, hbox: pGtkWidget;
			adj: pGtkAdjustment;
		begin
			window:= gtk_window_new(gtk_window_toplevel);
			gtk_window_set_title(pGtkWindow(window), 'Decimals');
			gtk_window_set_position(pGtkWindow(window), gtk_win_pos_center_on_parent);
			gtk_window_set_destroy_with_parent(pGtkWindow(window), true);
			gtk_window_set_resizable(pGtkWindow(window), false);
			if (MODE = 1) then
				gtk_window_set_transient_for(pGtkWindow(window), pGtkWindow(basicWindow))
			else
				gtk_window_set_transient_for(pGtkWindow(window), pGtkWindow(advancedWindow));
			g_signal_connect(window, 'destroy', g_callback(@gtk_widget_destroy), window);
			gtk_widget_realize(window);
			
			vbox:= gtk_vbox_new(false, 0);
			gtk_container_add(pGtkContainer(window), vbox);
			
			label_:= gtk_label_new('Set the number of decimals');
			gtk_box_pack_start(pGtkBox(vbox), label_, false, false, 0);
			
			adj:= pGtkAdjustment(gtk_adjustment_new(gfloat(DECIMAL_PLACES), 0.0, 7.0, 1.0, 1.0, 0.0));
			spinBtn:= gtk_spin_button_new(adj, 0, 0);
			gtk_box_pack_start(pGtkBox(vbox), spinBtn, false, false, 0);
			
			hbox:= gtk_hbox_new(false, 0);
			gtk_box_pack_start(pGtkBox(vbox), hbox, false, false, 0);
			
			button:= gtk_button_new_with_label('      Set      ');
			g_signal_connect(button, 'clicked', g_callback(@get_decimals), nil);
			gtk_box_pack_start(pGtkBox(hbox), button, false, false, 0);
			
			button:= gtk_button_new_with_label('     Close     ');
			g_signal_connect(g_object(button), 'clicked', g_callback(@destroy_child_window),
								pgpointer(window));
			gtk_box_pack_end(pGtkBox(hbox), button, false, false, 0);
			
			gtk_widget_show_all(window);
		end;
	
	
	procedure display_error(err: integer);
		var
			window, label_, button, vbox, img, hbox: pGtkWidget;
			pixbuf: pGdkPixbuf;
			d: string;
		begin
			case err of
				1 : d:='        Invalid characters       ';
				2 : d:='     Internal stack error: 1     ';
				3 : d:='     Internal stack error: 2     ';
				4 : d:='          Division by 0          ';
				5 : d:='       Negative square root      ';
				6 : d:=' % accepts only integer operands ';
				7 : d:=' Tangent undefined for 90 degrees';
				8 : d:='Cotangent undefined for 0 degrees';
				9 : d:='        log(0) is undefined      ';
				10: d:='Negative log results in imaginary';
				11: d:='        ln(0) is undefined       ';
				12: d:=' Negative ln results in imaginary';
				13: d:='           Memory full           ';
				14: d:='       Malformed expression      ';
			end;
		
			window:= gtk_window_new(gtk_window_toplevel);
			gtk_window_set_title(pGtkWindow(window), 'Error');
			gtk_window_set_position(pGtkWindow(window), gtk_win_pos_center_on_parent);
			gtk_window_set_destroy_with_parent(pGtkWindow(window), true);
			gtk_window_set_resizable(pGtkWindow(window), false);
			if (MODE = 1) then
				gtk_window_set_transient_for(pGtkWindow(window), pGtkWindow(basicWindow))
			else
				gtk_window_set_transient_for(pGtkWindow(window), pGtkWindow(advancedWindow));
			g_signal_connect(window, 'destroy', g_callback(@gtk_widget_destroy), window);
			gtk_widget_realize(window);
			
			pixbuf:= gdk_pixbuf_new_from_xpm_data(XPM_ERROR_SIGN);
			img:= gtk_image_new_from_pixbuf(pixbuf);
			
			vbox:= gtk_vbox_new(false, 0);
			gtk_container_add(pGtkContainer(window), vbox);
			
			gtk_box_pack_start(pGtkBox(vbox), img, false, false, 0);
			
			label_:= gtk_label_new(pchar(d));
			{$ifdef unix}
				gtk_widget_modify_font(label_, pango_font_description_from_string('DejaVu Sans Condensed 15'));
			{$endif}
			{$ifdef windows}
				gtk_widget_modify_font(label_, pango_font_description_from_string('Sans 15'));
			{$endif}

			gtk_box_pack_start(pGtkBox(vbox), label_, false, false, 0);
			
			hbox:= gtk_hbox_new(true, 10);
			gtk_box_pack_end(pGtkBox(vbox), hbox, false, false, 0);
			
			button:= gtk_button_new_with_label('     Okay  :(     ');
			g_signal_connect(g_object(button), 'clicked', g_callback(@destroy_child_window),
								pgpointer(window));
			gtk_box_pack_start(pGtkBox(hbox), button, false, false, 0);

			gtk_widget_show_all(window);
		end;
	
	
	(* gets the text from the calculator when "return" or "=" button is pressed
	* and also display the result *)
	procedure get_text(widget, entry: pGtkWidget);
		var
			entryText, res: pgchar;
		begin
			entryText:= gtk_entry_get_text(pGtkEntry(entry));
			input:= string(entryText);
			if (input <> evalStr) then
				infixStr:= input;
			// if input is dirty tell the user and do nothing
			if (verify_input(input) = false) then
				display_error(1)
			else begin
				// evaluate the expression
				res:= pgchar(compute_format(input));
				evalStr:= res;
				// no errors after evaluation, print the result
				if (ERROR = 0) then
					// new input has been given, evaluate and print the result
					if (input <> evalStr) then begin
						gtk_entry_set_text(pGtkEntry(entry), res);
						gtk_editable_set_position(pGtkEntry(entry), length(string(res)));
					end else begin
						// else print the original infix string
						gtk_entry_set_text(pGtkEntry(entry), pchar(infixStr));
						gtk_editable_set_position(pGtkEntry(entry), length(infixStr));
					end
				else
					case ERROR of
						1 : display_error(2);
						2 : display_error(3);
						3 : display_error(4);
						4 : display_error(5);
						5 : display_error(6);
						6 : display_error(7);
						7 : display_error(8);
						8 : display_error(9);
						9 : display_error(10);
						10: display_error(11);
						11: display_error(12);
						12: display_error(1);
						14: display_error(14);
					end;
			end;
		end;
		
		
	(* updates the screen to resemble the memory *)
	procedure update_memory();
		var
			i: byte;
		begin
			for i:=1 to 8 do
				gtk_label_set_text(pGtkLabel(listItems[i,2]), pchar(listValues[i,2]));
		end;
		
	
	procedure clear_memory();
		var
			i: byte;
		begin
			for i:=1 to 8 do
				listValues[i,2]:= '';
			update_memory();
		end;
	
	
	procedure memory_add(s: string);
		var
			i: byte;
			inserted: boolean = false;
		begin
			for i:=1 to 8 do
				if (listValues[i,2]= '') then begin
					listValues[i,2]:= s;
					inserted:= true;
					update_memory();
					break;
				end;

			if (not(inserted)) then
				display_error(13);
		end;
		
		
	procedure memory_remove();
		begin
			listValues[listSelected,2]:= '';
			update_memory();
		end;
	
	
	function memory_retrieve(): string;
		begin
			if (listSelected = 0) then
				result:= ''
			else
				result:= listValues[listSelected,2];
		end;
		
		
	procedure select_list_item(widget:pGtkWidget; data:pgpointer);
		begin
			val(pchar(data), listSelected);
		end;
		
		
	procedure create_list();
		var
			hbox, label_: pGtkWidget;
			i: byte;
			ds: string;
		begin
			list:= gtk_vbox_new(false, 0);
			gtk_widget_set_size_request(pGtkWidget(list), 200, 200);
			
			listValues[1,1]:= '1'; listValues[2,1]:= '2'; listValues[3,1]:= '3'; listValues[4,1]:= '4';
			listValues[5,1]:= '5'; listValues[6,1]:= '6'; listValues[7,1]:= '7'; listValues[8,1]:= '8';
			
			label_:= gtk_label_new('Memory');
			gtk_box_pack_start(pGtkBox(list), label_, false, false, 0);
			
			for i:=1 to 8 do begin
				listValues[i,2]:= '';
			
				hbox:= gtk_hbox_new(false, 2);
				gtk_box_pack_start(pGtkBox(list), hbox, false, false, 0);
				str(i, ds);
				ds:= concat(ds, '.');
				label_:= gtk_label_new(pchar(ds));
				gtk_widget_set_size_request(pGtkWidget(label_), 20, 20);
				gtk_box_pack_start(pGtkBox(hbox), label_, false, false, 0);
				
				listItems[i,1]:= gtk_button_new();
				listItems[i,2]:= gtk_label_new(nil);
				gtk_container_add(pGtkContainer(listItems[i,1]), listItems[i,2]);
				// some workaround this is...
				// on windows the widgets have different size than on unix-like systems
				//therefore they won't display the same. Here the labels/buttons that
				//contain the expressions/results the user wants to remember wouldn't show
				//the hole 8 slots on windows. By explicitly settings those widgets size
				//smaller than they would naturally want, the program behaves identical
				//on both platforms.
				{$ifdef windows}
					gtk_widget_set_size_request(pGtkWidget(listItems[i,1]), 170, 25);
				{$endif}
				{$ifdef unix}
					gtk_widget_set_size_request(pGtkWidget(listItems[i,1]), 170, -1);
				{$endif}
				gtk_button_set_relief(pGtkButton(listItems[i,1]), gtk_relief_none);
				g_signal_connect(listItems[i,1], 'clicked', g_callback(@select_list_item),
										pchar(listValues[i,1]));
				gtk_box_pack_start(pGtkBox(hbox), listItems[i,1], false, false, 2);
			end;
		end;
	
	
	(* updates the screen when events modifies the text on it *)
	procedure put_text(widget: pGtkWidget; data: pgpointer);
		var
			entryText: pgchar;
			pos, pos2: gint;
			s, ds: string;
		begin
			s:= pchar(data);

			if (MODE = 1) then 
				if (s = '=') then
					g_signal_emit_by_name(g_object(entryBasic), 'activate')
				else if (s = 'bcksp') then begin
					pos:= gtk_editable_get_position(pGtkEntry(entryBasic));
					gtk_editable_delete_text(pGtkEditable(entryBasic), pos-1, pos);
				end else if (s = 'clear') then begin
					gtk_entry_set_text(pGtkEntry(entryBasic), '');
					clicked:= false;
				end else if (s = 'm+') then begin
					entryText:= gtk_entry_get_text(pGtkEntry(entryBasic));
					input:= string(entryText);
					madd:= input;
				end else begin
					pos:= gtk_editable_get_position(pGtkEntry(entryBasic));
					
					if (s = 'sp') then begin
						gtk_editable_insert_text(pGtkEntry(entryBasic), ' ', 1, @pos);
						exit();
					end else if (s = 'mr') then begin
						gtk_editable_insert_text(pGtkEntry(entryBasic), pchar(madd), length(madd), @pos);
						exit();
					end;
					
					gtk_editable_insert_text(pGtkEntry(entryBasic), pchar(data), length(s), @pos);
					
					if (not(clicked)) then begin
						entryText:= gtk_entry_get_text(pGtkEntry(entryBasic));
						ds:= string(entryText);
						pos2:= length(ds);
						gtk_editable_set_position(pGtkEntry(entryBasic), pos2);
					end;
					
					if (pos <> pos2) then begin
						clicked:= true;
						gtk_editable_set_position(pGtkEntry(entryBasic), pos);
					end;
			end else
				if (EVAL = 1) then
					if (s = '=') then
						g_signal_emit_by_name(g_object(entryAdv), 'activate')
					else if (s = 'bcksp') then begin
						pos:= gtk_editable_get_position(pGtkEntry(entryAdv));
						gtk_editable_delete_text(pGtkEditable(entryAdv), pos-1, pos);
					end else if (s = 'clear') then begin
						gtk_entry_set_text(pGtkEntry(entryAdv), '');
						clicked:= false;
					end else if (s = 'ms') then
						if (memoryStatus = 1) then
							memory_show_hide(2)
						else
							memory_show_hide(1)
					else if (s = 'mc') then
						clear_memory()
					else if (s = 'm+_adv') then begin
						entryText:= gtk_entry_get_text(pGtkEntry(entryAdv));
						input:= string(entryText);
						madd:= input;
						memory_add(madd);
					end else if (s = 'm-') then
						memory_remove()
					else begin
						pos:= gtk_editable_get_position(pGtkEntry(entryAdv));
						
						if (s = 'sp') then begin
							gtk_editable_insert_text(pGtkEntry(entryAdv), ' ', 1, @pos);
							exit();
						end else if (s = 'mr') then begin
							ds:= memory_retrieve();
							gtk_editable_insert_text(pGtkEntry(entryAdv), pchar(ds), length(ds), @pos);
							exit();
						end;
						
						gtk_editable_insert_text(pGtkEntry(entryAdv), pchar(data), length(s), @pos);
					
						if (not(clicked)) then begin
							entryText:= gtk_entry_get_text(pGtkEntry(entryAdv));
							ds:= string(entryText);
							pos2:= length(ds);
							gtk_editable_set_position(pGtkEntry(entryAdv), pos2);
						end;
					
						if (pos <> pos2) then begin
							clicked:= true;
							gtk_editable_set_position(pGtkEntry(entryAdv), pos);
						end;
				end else
					if (s = '=') then
						g_signal_emit_by_name(g_object(entryAdv), 'activate')
					else if (s = 'bcksp') then begin
						pos:= gtk_editable_get_position(pGtkEntry(entryAdv));
						gtk_editable_delete_text(pGtkEditable(entryAdv), pos-1, pos);
					end else if (s = 'clear') then begin
						gtk_entry_set_text(pGtkEntry(entryAdv), '');
						clicked:= false;
					end else if (s = 'sin(') then
						gtk_entry_append_text(pGtkEntry(entryAdv), pchar('sin'))
					else if (s = 'cos(') then
						gtk_entry_append_text(pGtkEntry(entryAdv), pchar('cos'))
					else if (s = 'tan(') then
						gtk_entry_append_text(pGtkEntry(entryAdv), pchar('tan'))
					else if (s = 'cotan(') then
						gtk_entry_append_text(pGtkEntry(entryAdv), pchar('cotan'))
					else if (s = 'log(') then
						gtk_entry_append_text(pGtkEntry(entryAdv), pchar('log'))
					else if (s = 'ln(') then
						gtk_entry_append_text(pGtkEntry(entryAdv), pchar('ln'))
					else if (s = 'ms') then
						if (memoryStatus = 1) then
							memory_show_hide(2)
						else
							memory_show_hide(1)
					else if (s = 'mc') then
						clear_memory()
					else if (s = 'm+_adv') then begin
						entryText:= gtk_entry_get_text(pGtkEntry(entryAdv));
						input:= string(entryText);
						madd:= input;
						memory_add(madd);
					end else if (s = 'm-') then
						memory_remove()
					else begin
						pos:= gtk_editable_get_position(pGtkEntry(entryAdv));
						
						if (s = 'sp') then begin
							gtk_editable_insert_text(pGtkEntry(entryAdv), ' ', 1, @pos);
							exit();
						end else if (s = 'mr') then begin
							ds:= memory_retrieve();
							gtk_editable_insert_text(pGtkEntry(entryAdv), pchar(ds), length(ds), @pos);
							exit();
						end;
						
						gtk_editable_insert_text(pGtkEntry(entryAdv), pchar(data), length(s), @pos);
					
						if (not(clicked)) then begin
							entryText:= gtk_entry_get_text(pGtkEntry(entryAdv));
							ds:= string(entryText);
							pos2:= length(ds);
							gtk_editable_set_position(pGtkEntry(entryAdv), pos2);
						end;
					
						if (pos <> pos2) then begin
							clicked:= true;
							gtk_editable_set_position(pGtkEntry(entryAdv), pos);
						end;
					end;
		end;
	
	
	procedure make_menu_basic();
		var
			calcMenu, modeMenu, evalMenu, miscMenu,
			calcLabel, modeLabel, evalLabel, miscLabel,
			decimals, sep, quit,
			adv,
			infix, postfix,
			license, credits: pGtkWidget;
			modeGroup, evalGroup: pGSList;
		begin
			modeGroup:= nil; evalGroup:= nil;
			menuBasic:= gtk_menu_bar_new();
			
			calcMenu:= gtk_menu_new();
			modeMenu:= gtk_menu_new();
			evalMenu:= gtk_menu_new();
			miscMenu:= gtk_menu_new();
			
			calcLabel:= gtk_menu_item_new_with_label('Calculator');
			modeLabel:= gtk_menu_item_new_with_label('Mode');
			evalLabel:= gtk_menu_item_new_with_label('Evaluation');
			miscLabel:= gtk_menu_item_new_with_label('Misc');
			
			decimals:= gtk_menu_item_new_with_label('Decimals');
			sep:= gtk_separator_menu_item_new();
			quit:= gtk_menu_item_new_with_label('Quit');
			
			mbbasic:= gtk_radio_menu_item_new_with_label(modeGroup, 'Basic');
			modeGroup:= gtk_radio_menu_item_get_group(pGtkRadioMenuItem(mbbasic));
			adv:= gtk_radio_menu_item_new_with_label(modeGroup, 'Advanced');
			modeGroup:= gtk_radio_menu_item_get_group(pGtkRadioMenuItem(adv));
			
			infix:= gtk_radio_menu_item_new_with_label(evalGroup, 'Infix');
			evalGroup:= gtk_radio_menu_item_get_group(pGtkRadioMenuItem(infix));
			postfix:= gtk_radio_menu_item_new_with_label(evalGroup, 'Postfix');
			evalGroup:= gtk_radio_menu_item_get_group(pGtkRadioMenuItem(postfix));
			
			license:= gtk_menu_item_new_with_label('License');
			credits:= gtk_menu_item_new_with_label('Credits');
			
			gtk_menu_item_set_submenu(pGtkMenuItem(calcLabel), calcMenu);
			gtk_menu_shell_append(pGtkMenuShell(calcMenu), decimals);
			gtk_menu_shell_append(pGtkMenuShell(calcMenu), sep);
			gtk_menu_shell_append(pGtkMenuShell(calcMenu), quit);
			
			gtk_menu_item_set_submenu(pGtkMenuItem(modeLabel), modeMenu);
			gtk_menu_shell_append(pGtkMenuShell(modeMenu), mbbasic);
			gtk_menu_shell_append(pGtkMenuShell(modeMenu), adv);
			
			gtk_menu_item_set_submenu(pGtkMenuItem(evalLabel), evalMenu);
			gtk_menu_shell_append(pGtkMenuShell(evalMenu), infix);
			gtk_menu_shell_append(pGtkMenuShell(evalMenu), postfix);
			
			gtk_menu_item_set_submenu(pGtkMenuItem(miscLabel), miscMenu);
			gtk_menu_shell_append(pGtkMenuShell(miscMenu), license);
			gtk_menu_shell_append(pGtkMenuShell(miscMenu), credits);
			
			g_signal_connect(decimals, 'activate', g_callback(@change_decimals), nil);
			g_signal_connect(quit, 'activate', g_callback(@gtk_main_quit), nil);
			g_signal_connect(mbbasic, 'activate', g_callback(@switch_mode), pchar('1'));
			g_signal_connect(adv, 'activate', g_callback(@switch_mode), pchar('2'));
			g_signal_connect(infix, 'activate', g_callback(@switch_eval), pchar('1'));
			g_signal_connect(postfix, 'activate', g_callback(@switch_eval), pchar('2'));
			g_signal_connect(license, 'activate', g_callback(@show_license), nil);
			g_signal_connect(credits, 'activate', g_callback(@show_credits), nil);
			
			gtk_menu_shell_append(pGtkMenuShell(menuBasic), calcLabel);
			gtk_menu_shell_append(pGtkMenuShell(menuBasic), modeLabel);
			gtk_menu_shell_append(pGtkMenuShell(menuBasic), evalLabel);
			gtk_menu_shell_append(pGtkMenuShell(menuBasic), miscLabel);
		end;
	
		
	procedure make_menu_advanced();
		var
			calcMenu, modeMenu, evalMenu, miscMenu,
			calcLabel, modeLabel, evalLabel, miscLabel,
			decimals, sep, quit,
			basic,
			infix, postfix,
			license, credits: pGtkWidget;
			modeGroup, evalGroup: pGSList;
		begin
			modeGroup:= nil; evalGroup:= nil;
			menuAdvanced:= gtk_menu_bar_new();
			
			calcMenu:= gtk_menu_new();
			modeMenu:= gtk_menu_new();
			evalMenu:= gtk_menu_new();
			miscMenu:= gtk_menu_new();
			
			calcLabel:= gtk_menu_item_new_with_label('Calculator');
			modeLabel:= gtk_menu_item_new_with_label('Mode');
			evalLabel:= gtk_menu_item_new_with_label('Evaluation');
			miscLabel:= gtk_menu_item_new_with_label('Misc');
			
			decimals:= gtk_menu_item_new_with_label('Decimals');
			sep:= gtk_separator_menu_item_new();
			quit:= gtk_menu_item_new_with_label('Quit');
			
			basic:= gtk_radio_menu_item_new_with_label(modeGroup, 'Basic');
			modeGroup:= gtk_radio_menu_item_get_group(pGtkRadioMenuItem(basic));
			maadv:= gtk_radio_menu_item_new_with_label(modeGroup, 'Advanced');
			modeGroup:= gtk_radio_menu_item_get_group(pGtkRadioMenuItem(maadv));
			
			infix:= gtk_radio_menu_item_new_with_label(evalGroup, 'Infix');
			evalGroup:= gtk_radio_menu_item_get_group(pGtkRadioMenuItem(infix));
			postfix:= gtk_radio_menu_item_new_with_label(evalGroup, 'Postfix');
			evalGroup:= gtk_radio_menu_item_get_group(pGtkRadioMenuItem(postfix));
			
			license:= gtk_menu_item_new_with_label('License');
			credits:= gtk_menu_item_new_with_label('Credits');
			
			gtk_menu_item_set_submenu(pGtkMenuItem(calcLabel), calcMenu);
			gtk_menu_shell_append(pGtkMenuShell(calcMenu), decimals);
			gtk_menu_shell_append(pGtkMenuShell(calcMenu), sep);
			gtk_menu_shell_append(pGtkMenuShell(calcMenu), quit);
			
			gtk_menu_item_set_submenu(pGtkMenuItem(modeLabel), modeMenu);
			gtk_menu_shell_append(pGtkMenuShell(modeMenu), basic);
			gtk_menu_shell_append(pGtkMenuShell(modeMenu), maadv);
			
			gtk_menu_item_set_submenu(pGtkMenuItem(evalLabel), evalMenu);
			gtk_menu_shell_append(pGtkMenuShell(evalMenu), infix);
			gtk_menu_shell_append(pGtkMenuShell(evalMenu), postfix);
			
			gtk_menu_item_set_submenu(pGtkMenuItem(miscLabel), miscMenu);
			gtk_menu_shell_append(pGtkMenuShell(miscMenu), license);
			gtk_menu_shell_append(pGtkMenuShell(miscMenu), credits);
			
			g_signal_connect(decimals, 'activate', g_callback(@change_decimals), nil);
			g_signal_connect(quit, 'activate', g_callback(@gtk_main_quit), nil);
			g_signal_connect(basic, 'activate', g_callback(@switch_mode), pchar('1'));
			g_signal_connect(maadv, 'activate', g_callback(@switch_mode), pchar('2'));
			g_signal_connect(infix, 'activate', g_callback(@switch_eval), pchar('1'));
			g_signal_connect(postfix, 'activate', g_callback(@switch_eval), pchar('2'));
			g_signal_connect(license, 'activate', g_callback(@show_license), nil);
			g_signal_connect(credits, 'activate', g_callback(@show_credits), nil);
			
			gtk_menu_shell_append(pGtkMenuShell(menuAdvanced), calcLabel);
			gtk_menu_shell_append(pGtkMenuShell(menuAdvanced), modeLabel);
			gtk_menu_shell_append(pGtkMenuShell(menuAdvanced), evalLabel);
			gtk_menu_shell_append(pGtkMenuShell(menuAdvanced), miscLabel);
		end;
	
	
	(* creates the gui for calc basic *)
	procedure basic_calculator();
		var
			vbox, button, table: pGtkWidget;
		begin
			basicWindow:= gtk_window_new(gtk_window_toplevel);
			gtk_window_set_title(pGtkWindow(basicWindow), 'Calculator');
			gtk_window_set_resizable(pGtkWindow(basicWindow), false);
			gtk_window_set_icon(pGtkWindow(basicWindow), progIcon);
			gtk_window_set_position(pGtkWindow(basicWindow), gtk_win_pos_center_always);
			g_signal_connect(basicWindow, 'destroy', g_callback(@gtk_main_quit), nil);
			
			make_menu_basic();
			
			vbox:= gtk_vbox_new(false, 0);
			gtk_container_add(pGtkContainer(basicWindow), vbox);
			
			gtk_box_pack_start(pGtkBox(vbox), menuBasic, false, false, 0);
			
			entryBasic:= gtk_entry_new();
			gtk_entry_set_max_length(pGtkEntry(entryBasic), LIMIT);
			gtk_entry_set_alignment(pGtkEntry(entryBasic), 1);
			{$ifdef unix}
				gtk_widget_modify_font(entryBasic, pango_font_description_from_string('DejaVu Sans Condensed 15'));
			{$endif}
			{$ifdef windows}
				gtk_widget_modify_font(entryBasic, pango_font_description_from_string('Sans 15'));
			{$endif}
			g_signal_connect(entryBasic, 'activate', g_callback(@get_text), entryBasic);
			gtk_box_pack_start(pGtkBox(vbox), entryBasic, false, false, 5);
			
			table:= gtk_table_new(5, 5, true);
			gtk_box_pack_start(pGtkBox(vbox), table, false, false, 0);
			
			// 1st row
			button:= gtk_button_new_with_label('bcksp');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('bcksp'));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 0, 1);
			
			button:= gtk_button_new_with_label('space');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('sp'));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 0 , 1);
			
			button:= gtk_button_new_with_label('clear');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('clear'));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 5, 0, 1);
			
			// 2nd row
			button:= gtk_button_new_with_label('m+');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('m+'));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 1, 2);
			
			button:= gtk_button_new_with_label('7');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('7'));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 1, 2);
			
			button:= gtk_button_new_with_label('8');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('8'));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 1, 2);
			
			button:= gtk_button_new_with_label('9');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('9'));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 1, 2);

			// '/' sign
			button:= gtk_button_new_with_label(pgchar(UTF8String(#$C3#$B7)));
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar(UTF8String(#$C3#$B7)));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 5, 1, 2);
			
			// 3rd row
			button:= gtk_button_new_with_label('mr');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('mr'));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 2, 3);
			
			button:= gtk_button_new_with_label('4');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('4'));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 2, 3);
			
			button:= gtk_button_new_with_label('5');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('5'));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 2, 3);
			
			button:= gtk_button_new_with_label('6');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('6'));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 2, 3);
			
			// '*' sign
			button:= gtk_button_new_with_label(pgchar(UTF8String(#$C3#$97)));
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar(UTF8String(#$C3#$97)));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 5, 2, 3);
			
			// 4th row
			button:= gtk_button_new_with_label('(');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('('));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 3, 4);
			
			button:= gtk_button_new_with_label('1');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('1'));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 3, 4);
			
			button:= gtk_button_new_with_label('2');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('2'));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 3, 4);
			
			button:= gtk_button_new_with_label('3');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('3'));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 3, 4);
			
			button:= gtk_button_new_with_label('+');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('+'));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 5, 3, 4);
			
			// 5th row
			button:= gtk_button_new_with_label(')');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar(')'));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 4, 5);
			
			button:= gtk_button_new_with_label('0');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('0'));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 4, 5);
		
			button:= gtk_button_new_with_label('.');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('.'));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 4, 5);
			
			button:= gtk_button_new_with_label('=');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('='));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 4, 5);
			
			button:= gtk_button_new_with_label('-');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('-'));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 5, 4, 5);
		end;
	
	
	(* creates the gui for calc adv *)
	procedure advanced_calculator();
		var
			vbox, table, button, hbox: pGtkWidget;
		begin
			advancedWindow:= gtk_window_new(gtk_window_toplevel);
			gtk_window_set_title(pGtkWindow(advancedWindow), 'Calculator');
			gtk_window_set_resizable(pGtkWindow(advancedWindow), false);
			gtk_window_set_icon(pGtkWindow(advancedWindow), progIcon);
			gtk_window_set_position(pGtkWindow(advancedWindow), gtk_win_pos_center_always);
			gtk_window_set_default_size(pGtkWindow(advancedWindow), -1, 280);
			g_signal_connect(advancedWindow, 'destroy', g_callback(@gtk_main_quit), nil);
			
			make_menu_advanced();
			create_list();
			
			hbox:= gtk_hbox_new(false, 0);
			gtk_container_add(pGtkContainer(advancedWindow), hbox);
			gtk_box_pack_start(pGtkBox(hbox), list, false, false, 0);
			
			vbox:= gtk_vbox_new(false, 0);
			gtk_box_pack_start(pGtkBox(hbox), vbox, false, false, 0);
			
			gtk_box_pack_start(pGtkBox(vbox), menuAdvanced, false, false, 0);
			
			entryAdv:= gtk_entry_new_with_max_length(LIMIT);
			gtk_entry_set_alignment(pGtkEntry(entryAdv), 1);
			{$ifdef unix}
				gtk_widget_modify_font(entryAdv, pango_font_description_from_string('DejaVu Sans Condensed 15'));
			{$endif}
			{$ifdef windows}
				gtk_widget_modify_font(entryAdv, pango_font_description_from_string('Sans 15'));
			{$endif}
			g_signal_connect(entryAdv, 'activate', g_callback(@get_text), entryAdv);
			
			gtk_box_pack_start(pGtkBox(vbox), entryAdv, false, false, 5);
			
			table:= gtk_table_new(7, 6, true);
			gtk_box_pack_start(pGtkBox(vbox), table, false, false, 0);
			
			// 1st row
			button:= gtk_button_new_with_label('ms');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('ms'));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 0, 1);
			
			button:= gtk_button_new_with_label('bcksp');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('bcksp'));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 0, 1);
			
			button:= gtk_button_new_with_label('space');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('sp'));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 5, 0 , 1);
			
			button:= gtk_button_new_with_label('clear');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('clear'));
			gtk_table_attach_defaults(pGtkTable(table), button, 5, 6, 0, 1);
			
			// 2nd row
			button:= gtk_button_new_with_label('m+');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('m+_adv'));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 1, 2);
			
			button:= gtk_button_new_with_label('sin');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('sin('));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 1, 2);
			
			button:= gtk_button_new_with_label('tan');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('tan('));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 1, 2);
			
			button:= gtk_button_new_with_label('log');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('log('));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 1, 2);
			
			// 'pi' sign
			button:= gtk_button_new_with_label(pgchar(UTF8String(#$CF#$80)));
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar(UTF8String(#$CF#$80)));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 6, 1, 2);
			
			// 3rd row
			button:= gtk_button_new_with_label('m-');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('m-'));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 2, 3);
			
			button:= gtk_button_new_with_label('cos');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('cos('));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 2, 3);
			
			button:= gtk_button_new_with_label('cotan');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('cotan('));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 2, 3);
			
			button:= gtk_button_new_with_label('ln');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('ln('));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 2, 3);
			
			button:= gtk_button_new_with_label('e');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('e'));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 6, 2, 3);
			
			// 4th row
			button:= gtk_button_new_with_label('mr');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('mr'));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 3, 4);
			
			button:= gtk_button_new_with_label('7');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('7'));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 3, 4);
			
			button:= gtk_button_new_with_label('8');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('8'));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 3, 4);
			
			button:= gtk_button_new_with_label('9');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('9'));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 3, 4);
			
			// '*' sign
			button:= gtk_button_new_with_label(pgchar(UTF8String(#$C3#$97)));
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar(UTF8String(#$C3#$97)));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 5, 3, 4);
			
			button:= gtk_button_new_with_label('^');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('^'));
			gtk_table_attach_defaults(pGtkTable(table), button, 5, 6, 3, 4);
			
			// 5th row
			button:= gtk_button_new_with_label('mc');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('mc'));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 4, 5);
			
			button:= gtk_button_new_with_label('4');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('4'));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 4, 5);
			
			button:= gtk_button_new_with_label('5');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('5'));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 4, 5);
			
			button:= gtk_button_new_with_label('6');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('6'));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 4, 5);
			
			// '/' sign
			button:= gtk_button_new_with_label(pgchar(UTF8String(#$C3#$B7)));
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar(UTF8String(#$C3#$B7)));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 5, 4, 5);
			
			// 'sqrt' sign
			button:= gtk_button_new_with_label(pgchar(UTF8String(#$E2#$88#$9A)));
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar(UTF8String(#$E2#$88#$9A)));
			gtk_table_attach_defaults(pGtkTable(table), button, 5, 6, 4, 5);
			
			// 6th row
			button:= gtk_button_new_with_label('(');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('('));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 5, 6);
			
			button:= gtk_button_new_with_label('1');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('1'));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 5, 6);
			
			button:= gtk_button_new_with_label('2');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('2'));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 5, 6);
			
			button:= gtk_button_new_with_label('3');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('3'));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 4, 5, 6);
			
			button:= gtk_button_new_with_label('+');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('+'));
			gtk_table_attach_defaults(pGtkTable(table), button, 4, 5, 5, 6);
			
			button:= gtk_button_new_with_label('%');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('%'));
			gtk_table_attach_defaults(pGtkTable(table), button, 5, 6, 5, 6);
			
			// 7th row
			button:= gtk_button_new_with_label(')');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar(')'));
			gtk_table_attach_defaults(pGtkTable(table), button, 0, 1, 6, 7);
		
			button:= gtk_button_new_with_label('0');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('0'));
			gtk_table_attach_defaults(pGtkTable(table), button, 1, 2, 6, 7);
			
			button:= gtk_button_new_with_label('.');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('.'));
			gtk_table_attach_defaults(pGtkTable(table), button, 2, 3, 6, 7);
			
			button:= gtk_button_new_with_label('=');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('='));
			gtk_table_attach_defaults(pGtkTable(table), button, 3, 5, 6, 7);
			
			button:= gtk_button_new_with_label('-');
			g_signal_connect(button, 'clicked', g_callback(@put_text), pchar('-'));
			gtk_table_attach_defaults(pGtkTable(table), button, 5, 6, 6, 7);
		end;
	
	
	(* starts the program with the default values *)
	procedure start();
		begin
			gtk_init(@argc, @argv);
			{$ifdef windows}
				gtk_rc_parse('theme');
			{$endif}
			
			set_defaults();
		
			basic_calculator();
			advanced_calculator();
			gtk_widget_show_all(basicWindow);
		
			gtk_main();
		end;

end.
