/datum/computer_file/program/party_manager
	filename = "prtymangr"
	filedesc = "Official Party Management"
	extended_desc = "This program allows you to create an official party and also manage and view existing parties."
	requires_ntnet = 1
	size = 3
	nanomodule_path = /datum/nano_module/program/party_manager/

/datum/nano_module/program/party_manager/
	name = "Official Party Management"
	var/index = 0
	var/page_msg
	var/authuser

	var/user_uid
	var/can_login

	// SELECTED PARTY
	var/datum/party/current_party
	var/is_leader

	var/party_announcement

	// REGISTRATION
	var/p_name = " "
	var/p_slogan = " "
	var/p_desc = " "

	var/acc_no
	var/acc_pin

	var/party_pass = " "
	var/reg_error = "*Fields marked with an asterisk are required."

/datum/nano_module/program/party_manager/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = default_state)
	var/list/data = list()
	if(program)
		data = program.get_header_data()

	data["index"] = index
	data["page_msg"] = page_msg
	data["parties"] = political_parties


	var/obj/item/weapon/card/id/I = user.GetIdCard()

	if(!ishuman(user) || !istype(I) || !I.registered_name)
		data["authuser"] = "Anonymous"
		can_login = 0
	else
		var/mob/living/carbon/human/H = user
		data["authuser"] = "[I.registered_name] - [I.assignment ? I.assignment : "(Unknown)"]"
		can_login = 1
		user_uid = H.client.prefs.unique_id
		data["user_uid"] = user_uid
		data["party_leader"] = I.registered_name



	if(current_party)
		party_announcement = current_party.party_message
		data["is_leader"] = is_party_leader(user_uid, current_party)
		data["current_party_name"] = current_party.name
		data["current_party"] = current_party
		data["party_announcement"] = party_announcement


	if(can_login)
		data["unique_id"] = user_uid
		acc_no = I.associated_account_number
		acc_pin = I.associated_pin_number


	//Registration
	data["p_name"] = p_name
	data["p_slogan"] = p_slogan
	data["p_desc"] = p_desc
	data["acc_no"] = acc_no
	data["acc_pin"] = acc_pin
//	data["party_email"] = party_email
	data["reg_error"] = reg_error
	data["party_pass"] = party_pass


	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "political_party.tmpl", "Official Party Management", 690, 680, state = state)
		if(program.update_layout())
			ui.auto_update_layout = 1
		ui.set_auto_update(1)
		ui.set_initial_data(data)
		ui.open()

/datum/nano_module/program/party_manager/proc/reset_fields()
	p_name = initial(p_name)
	p_desc = initial(p_desc)
	p_slogan = initial(p_slogan)
	party_pass = initial(party_pass)

/datum/nano_module/program/party_manager/Topic(href, href_list)
	if(..()) return 1

	if(href_list["back"])
		. = 1
		index = 0
		reset_fields()

	if(href_list["login"])
		. = 1
		index = 4
		reset_fields()

	if(href_list["register_party"])
		. = 1
		if(!ishuman(usr) || !can_login)
			index = 2
		else
			index = 1
			page_msg = "You are not authorized to access this page."

	if(href_list["view_parties"])
		. = 1
		get_all_parties(usr)

	if(href_list["set_party_name"])
		. = 1
		var/pa_name = sanitize(copytext(input(usr, "Enter your party name (40 chars max)", "Party Manager", null)  as text,1,40))
		if(!pa_name)
			return
		p_name = pa_name

	if(href_list["edit_party_name"])
		. = 1

		var/pa_name = sanitize(copytext(input(usr, "Enter your party name (40 chars max)", "Party Manager", null)  as text,1,40))
		if(!pa_name)
			return
		p_name = pa_name


	if(href_list["set_party_slogan"])
		. = 1
		p_slogan = sanitize(copytext(input(usr, "Enter your party's slogan (80 chars max)", "Party Manager", null)  as text,1,80))
		if(!p_slogan)
			p_slogan = initial(p_slogan)
			return

	if(href_list["set_party_desc"])
		. = 1
		p_desc = sanitize(copytext(input(usr, "Enter your party's description (200 chars max)", "Picket Message", null)  as message,1,200))
		if(!p_desc)
			return
/*

	if(href_list["set_party_email"])
		. = 1
		p_name = sanitize(copytext(input(usr, "Enter your party's email", "Party Manager", null)  as text,1,60))
		if(!p_name)
			return
*/
	if(href_list["set_party_pass"])
		. = 1
		party_pass = sanitize(copytext(input(usr, "Enter the password your party will use. (15 characters max)", "Party Manager", null)  as text,1,15))
		if(!party_pass)
			return

	if(href_list["submit_new_party"])
		. = 1
		if(p_name == initial(p_name))
			reg_error = "You need to enter a party name!"
			return

		if(check_party_name_exist(p_name))
			reg_error = "This party name already exists. Please choose another."
			return

		if(p_slogan == initial(p_slogan))
			reg_error = "A party slogan is required!"
			return

		if(p_desc == initial(p_desc))
			reg_error = "The party description cannot be left blank!"
			return

		if(party_pass == initial(party_pass))
			reg_error = "A password is required!"
			return

		for(var/datum/party/K in political_parties)
			if(K.name == p_name)
				reg_error = "The name \"[p_name]\" already exists."
				break
				return


		if("No" == alert("Create [p_name] party for 3,500 credits?", "Create Party", "No", "Yes"))
			return

		if(!attempt_account_access(acc_no, acc_pin, 2) || !charge_to_account(acc_no, "Party Registrar", "[p_name] registration", "Polluxian Party Registration", -3500))
			reg_error = "There was an error charging your bank account. Please contact your bank's administrator."
			return
		else
			var/datum/party/P = create_new_party(p_name, p_desc, p_slogan, party_pass, usr)
			message_admins("Party created.")

			index = 2
			page_msg = "Party created! <br><br>\
			<b>Party Name:</b> [P.name]<p>\
			<b>Party Unique ID:</b> [P.id] (Use this as a login.)<p>\
			<b>Party Password:</b> [P.password]"

			reset_fields()

	if(href_list["party_logout"])
		reset_fields()
		current_party = null
		page_msg = "Successfully logged out!"
		index = 2

	if(href_list["party_login"])
		. = 1

		if(p_name == initial(p_name))
			reg_error = "You need to enter a party name!"
			return

		if(!check_party_name_exist(p_name))
			reg_error = "This party does not exist."
			return

		var/datum/party/P

		P = get_party_by_name(p_name)

		if(!P)
			message_admins("Could not find [P.name].")
			page_msg = "Unable to login to this party. Please contact the party administration."
			return

		if(try_auth_party(P, p_name, party_pass))
			page_msg = "Login successful!"
			message_admins("Success! Logged into [P.name].")
			current_party = P
			party_announcement = current_party.party_message
			index = 5
		else
			message_admins("Login failed for [P.name] with [party_pass].")
			page_msg = "Login failed. Please check the password or party name."

	if(href_list["party_settings"])
		. = 1
		index = 6

	if(href_list["manage_members"])
		. = 1
		index = 7

	if(href_list["party_announcement"])
		. = 1
		party_announcement = sanitize(copytext(input(usr, "Enter a party announcement, this will be viewed by party members only.", "Party Announcement", current_party.party_message)  as message,1,200))
		if(!party_announcement)
			return
		if(current_party)
			current_party.party_message = party_announcement

	if(href_list["set_primary_color"])
		. = 1
		var/prim_color
		prim_color = input(user,"Choose Color") as color
		if(!prim_color)
			return

		current_party.primary_color = prim_color


	if(href_list["set_secondary_color"])
		. = 1
		var/sec_color
		sec_color = input(user,"Choose Color") as color
		if(!sec_color)
			return

		current_party.secondary_color = sec_color

	if(href_list["rename_party"])
		. = 1
		var/new_name
		new_name = sanitize(copytext(input(usr, "Enter a new party name.", "Party Name", current_party.party_message)  as text,1,40))
		if(!new_name)
			return
		if(current_party)
			current_party.name = new_name


	if(href_list["Assign New Leader"])
		. = 1
		if(current_party)
			var/datum/party_member/p_members = current_party.members
			if(!p_members)
				return
			else
				var/new_leader = input(user, "Select a new party leader", "New Leader")  as null|anything in p_members
				var/choice = alert(player.current,"Resign as party leader and set [new_leader.name] as new party leader?","[new_leader.name] as new party leader?","Yes","No")
				if(choice == "Yes")
					current_party.party_leader = new_leader
				else
					return

	if(href_list["apply_for_party"])
		. = 1
		var/new_name
		new_name = sanitize(copytext(input(usr, "Enter a new party name.", "Party Name", current_party.party_message)  as text,1,40))
		if(!new_name)
			return
		if(current_party)
			current_party.name = new_name
