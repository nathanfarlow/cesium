; common routines for working with things involving settings

settings_load:
	ld	hl,settings_appvar
	call	util_find_var			; lookup the settings appvar
	jr	c,settings_create_default	; create it if it doesn't exist
	call	_ChkInRam
	push	af
	call	z,_Arc_Unarc			; archive it
	pop	af
	jr	z,settings_load			; find it again
settings_get_data:
	ex	de,hl
	ld	de,9
	add	hl,de
	ld	e,(hl)
	add	hl,de
	inc	hl
	inc	hl
	inc	hl
	ld	de,settings_data
	ld	bc,settings_size
	ldir
	ld	a,(setting_config)
	ld	(iy + settings_flag),a
	ret

settings_create_default:
	ld	hl,settings_appvar_size * 2	; just have at least double this
	push	hl
	call	_EnoughMem
	pop	hl
	jp	c,exit_full
	call	_CreateAppVar
	inc	de
	inc	de
	ex	de,hl
	ld	(hl),color_primary_default
	inc	hl
	ld	(hl),color_secondary_default
	inc	hl
	ld	(hl),setting_config_default
	inc	hl
	ld	(hl),0
	jr	settings_load

settings_save:
	ld	hl,settings_appvar
	call	util_find_var
	call	_ChkInRam
	push	af
	call	nz,_Arc_Unarc
	pop	af
	jr	nz,settings_save
	ld	a,(iy + settings_flag)
	ld	(setting_config),a
	inc	de
	inc	de
	ld	hl,settings_data
	ld	bc,settings_size
	ldir
	ld	hl,settings_appvar
	call	util_find_var
	jp	_Arc_Unarc

settings_show:
	xor	a,a
	ld	(current_option_selection),a			; start on the first menu item
.draw:
	call	setting_draw_options

settings_get:
	call	util_show_time
	call	lcd_blit
	call	_GetCSC
	ld	hl,settings_show.draw
	push	hl
	ld	ix,current_option_selection
	cp	a,skStore
	jp	z,password_modify
	cp	a,skLeft
	jp	z,setting_color_left
	cp	a,skRight
	jp	z,setting_color_right
	cp	a,skDown
	jp	z,setting_move_down
	cp	a,skUp
	jp	z,setting_move_up
	cp	a,sk2nd
	jp	z,setting_toggle
	cp	a,skEnter
	jp	z,setting_toggle
	pop	hl
	cp	a,skDel
	jr	z,setting_set_and_save
	cp	a,skClear
	jr	z,setting_set_and_save
	jr	settings_get
setting_set_and_save:
	call	settings_save			; check if on disabled apps screen
	ld	a,(current_screen)
	cp	a,screen_apps
	jr	z,settings_return
	bit	setting_special_directories,(iy + settings_flag)
	jr	nz,settings_return
	call	util_init_selection_screen
	ld	a,screen_programs
	ld	(current_screen),a
settings_return:
	jp	main_settings

setting_move_down:
	ld	a,(ix)
	cp	a,6
	ret	z
	inc	a
	ld	(ix),a
	ret

setting_move_up:
	ld	a,(ix)
	or	a,a
	ret	z
	dec	a
	ld	(ix),a
	ret

setting_toggle:
	ld	a,(ix)
	or	a,a
	jr	z,setting_open_colors	; convert the option to one-hot
	ld	b,a
	xor	a, a
.one_hot:
	rla
	djnz	.one_hot
	xor	a,(iy + settings_flag)
	ld	(iy + settings_flag),a
	ret

setting_open_colors:
	call	setting_draw_options
	call	gui_draw_color_tables
.loop:
	call	util_show_time
	call	lcd_blit
	call	_GetCSC
	ld	hl,setting_open_colors
	push	hl
	cp	a,skLeft
	jr	z,setting_color_left
	cp	a,skRight
	jr	z,setting_color_right
	cp	a,skDown
	jr	z,setting_color_down
	cp	a,skUp
	jr	z,setting_color_up
	cp	a,sk2nd
	jr	z,setting_color_select
	cp	a,skEnter
	jr	z,setting_color_select
	cp	a,skMode
	jr	z,setting_color_swap
	pop	hl
	cp	a,skClear
	jp	z,settings_show.draw
	cp	a,skDel
	jp	z,settings_show.draw
	jr	.loop

setting_color_left:
	ret
setting_color_right:
	ret
setting_color_down:
	ret
setting_color_up:
	ret
setting_color_select:
	ret
setting_color_swap:
	ret

setting_draw_options:
	call	gui_draw_cesium_info

	print	string_general_settings, 10, 30
	print	string_setting_color, 25, 53
	print	string_setting_indicator, 25, 76
	print	string_setting_list_count, 25, 99
	print	string_setting_clock, 25, 122
	print	string_setting_ram_backup, 25, 145
	print	string_setting_special_directories, 25, 168
	print	string_setting_enable_shortcuts, 25, 191

	xor	a,a
	inc	a				; color is always set
	draw_highlightable_option 10, 52, 18, 60, 0
	bit	setting_basic_indicator,(iy + settings_flag)
	draw_highlightable_option 10, 75, 18, 83, 1
	bit	setting_list_count,(iy + settings_flag)
	draw_highlightable_option 10, 98, 18, 106, 2
	bit	setting_clock,(iy + settings_flag)
	draw_highlightable_option 10, 121, 18, 129, 3
	bit	setting_ram_backup,(iy + settings_flag)
	draw_highlightable_option 10, 144, 18, 152, 4
	bit	setting_special_directories,(iy + settings_flag)
	draw_highlightable_option 10, 167, 18, 175, 5
	bit	setting_enable_shortcuts,(iy + settings_flag)
	draw_highlightable_option 10, 190, 18, 198, 6
	ret

settings_appvar:
	db	appvarObj, cesium_name, 0