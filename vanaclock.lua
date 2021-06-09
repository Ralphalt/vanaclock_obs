--[[
OBSでヴァナ時間をテキストとして表示するスクリプト
vanaclock.lua
2021/06/09
Ralphalt

使い方
1.OBSの「ツール」→「スクリプト」を開き、「スクリプト」タグの「ロードしたスクリプト」に本ファイルを追加する
2.ソースにテキスト(GDI+)を追加し、名前を付ける
3.「ツール」→「スクリプト」を開き、「スクリプト」タグの「ロードしたスクリプト」で本ファイルを選択し、
 「Display Text Source欄」に2.でつけた名前を記入する
4.シーンをアクティブにすると動作します。サイズ変更等はテキストが表示されてから実施してください。

]]

obs           = obslua
source_name   = ""
tick          = 200

last_text     = ""
format        = ""
activated     = false

utc_offset    = 9 --JST(not in use)
origin        = os.time({ year = 2002, month = 1, day = 1, hour = 0, min = 0, sec = 0, isdst = false}) --FF11 Service epoc (JST)

vorigin       = 886 * 12 * 30 * 24 * 60 * 60 --Vana-Diel epoc
		--(((((934 * 12 + (8 - 1)) * 30) + (4 - 1)) * 24) + 18) * 60 * 60

vMoonage      = { '二十日月', '二十六夜', '新月', '三日月', '七日月', '上弦の月',  '十日月', '十三夜', '満月', '十六夜', '居待月', '下弦の月'}
vWeekday      = { '火', '土', '水', '風', '氷', '雷', '光', '闇' }

-- Function to set the clock text
function set_clock_text()
	local timediff = os.difftime(os.time(), origin)
        local vYear, vMonth, vDay, vHour, vMinute, vWeek, vMoon = convert_realtime_to_vanatime(timediff)

	local text = string.format("%s/%s/%s(%s) %s:%s [%s]",vYear, vMonth, vDay, vWeekday[vWeek], vHour, vMinute, vMoonage[vMoon])
	if text ~= last_text then
		local source = obs.obs_get_source_by_name(source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", text)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end
	end

	last_text = text
end

function timer_callback()
	set_clock_text()
end

function convert_realtime_to_vanatime(timediff)
	local vtimediff = timediff * 25
	local vtime = vorigin + vtimediff
	
	local vWeek = math.floor(vtime / (24 * 60 * 60)) % 8 + 1
	local vMoon = math.floor( (vtime + 24 * 60 * 60 * 2) / (24 * 60 * 60 * 7)) % 12 + 1
	
	local vYear = math.floor( vtime / (360 * 24 * 60 * 60))
	vtime = vtime % (360 * 24 * 60 * 60)
	if vYear < 1000 then
		vYear = '0' .. tostring(vYear)
	else
		vYear = tostring(vYear)
	end

	local vMonth = math.floor( vtime / (30 * 24 * 60 * 60)) + 1
	vtime = vtime % (30 * 24 * 60 * 60)
	if vMonth < 10 then
		vMonth = '0' .. tostring(vMonth)
	else
		vMonth = tostring(vMonth)
	end

	local vDay = math.floor( vtime / (24 * 60 * 60)) + 1
	vtime = vtime % (24 * 60 * 60)
	if vDay < 10 then
		vDay = '0' .. tostring(vDay)
	else
		vDay = tostring(vDay)
	end

	local vHour = math.floor( vtime / (60 * 60))
	vtime = vtime % (60 * 60)
	if vHour < 10 then
		vHour = '0' .. tostring(vHour)
	else
		vHour = tostring(vHour)
	end

	local vMinute = math.floor( vtime / 60)
	if vMinute < 10 then
		vMinute = '0' .. tostring(vMinute)
	else
		vMinute = tostring(vMinute)
	end

        return vYear, vMonth, vDay, vHour, vMinute, vWeek, vMoon 
end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		set_clock_text()
		obs.timer_add(timer_callback, tick)
	else
		obs.timer_remove(timer_callback)
	end
end

-- Called when a source is activated/deactivated
function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end

function reset(pressed)
	if not pressed then
		return
	end

	activate(false)
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
		activate(active)
	end
end

----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()

	local p = obs.obs_properties_add_list(props, "source", "Display Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)

	--obs.obs_properties_add_text(props, "format", "Format", obs.OBS_TEXT_DEFAULT)

	return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Sets a text source to act as a clock in Vana-Diel when the source is active.\n\nMade by Ralphalt"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
	activate(false)

	source_name = obs.obs_data_get_string(settings, "source")
	--format = obs.obs_data_get_string(settings, "format")

	reset(true)
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
	--obs.obs_data_set_default_string(settings, "format", "%Y/%m/%d %H:%M:%S")
end

-- A function named script_save will be called when the script is saved
function script_save(settings)
end

-- a function named script_load will be called on startup
function script_load(settings)
	-- Connect activation/deactivation signal callbacks
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)
end