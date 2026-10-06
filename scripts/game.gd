extends Control

const SAVE_PATH := "user://star_garden_save.json"
const MONTH_NAMES: Array[String] = ["봄 1월", "봄 2월", "봄 3월", "봄 4월", "여름 1월", "여름 2월", "여름 3월", "여름 4월", "가을 1월", "가을 2월", "가을 3월", "가을 4월"]
const SIGNS: Array[Dictionary] = [
	{"name": "염소자리", "month": 1, "day": 19, "stat": "도덕", "element": "대지"},
	{"name": "물병자리", "month": 2, "day": 18, "stat": "마력", "element": "바람"},
	{"name": "물고기자리", "month": 3, "day": 20, "stat": "예술", "element": "물"},
	{"name": "양자리", "month": 4, "day": 19, "stat": "체력", "element": "불"},
	{"name": "황소자리", "month": 5, "day": 20, "stat": "건강", "element": "대지"},
	{"name": "쌍둥이자리", "month": 6, "day": 20, "stat": "지식", "element": "바람"},
	{"name": "게자리", "month": 7, "day": 22, "stat": "도덕", "element": "물"},
	{"name": "사자자리", "month": 8, "day": 22, "stat": "매력", "element": "불"},
	{"name": "처녀자리", "month": 9, "day": 22, "stat": "지식", "element": "대지"},
	{"name": "천칭자리", "month": 10, "day": 22, "stat": "예술", "element": "바람"},
	{"name": "전갈자리", "month": 11, "day": 21, "stat": "마력", "element": "물"},
	{"name": "사수자리", "month": 12, "day": 21, "stat": "체력", "element": "불"}
]
const ACTIONS: Dictionary = {
	"academy": {"title": "별빛 학원", "body": "지식과 마력을 배웁니다.", "cost": 45},
	"atelier": {"title": "화실 수업", "body": "예술 감각과 매력을 기릅니다.", "cost": 40},
	"training": {"title": "검술 훈련", "body": "체력과 용기를 키웁니다.", "cost": 25},
	"cafe": {"title": "찻집 아르바이트", "body": "생활비를 벌고 사교성을 배웁니다.", "cost": 0},
	"farm": {"title": "약초 농장 일", "body": "성실함과 체력을 기릅니다.", "cost": 0},
	"adventure": {"title": "별의 탑 던전", "body": "지식과 마력으로 봉인을 풀고 다음 층을 공략합니다.", "cost": 20},
	"rest": {"title": "집에서 휴식", "body": "건강을 회복하고 스트레스를 풉니다.", "cost": 0}
}

var player_name: String = ""
var birth_year: int = 2012
var birth_month: int = 4
var birth_day: int = 20
var zodiac: Dictionary = {}
var fortune_number: int = 1
var dungeon_floor: int = 1
var stardust: int = 0
var month_index: int = 0
var selected_action: String = "academy"
var gold: int = 420
var stats: Dictionary = {"건강": 72, "체력": 36, "지식": 42, "마력": 24, "예술": 38, "매력": 45, "도덕": 55, "스트레스": 18}
var log_lines: Array[String] = []
var stat_labels: Dictionary = {}
var date_label: Label
var gold_label: Label
var selected_label: Label
var log_label: Label
var ending_panel: PanelContainer
var action_buttons: Dictionary = {}
var profile_summary_label: Label
var onboarding_layer: CanvasLayer
var onboarding_hint: Label
var name_input: LineEdit
var year_input: SpinBox
var month_input: SpinBox
var day_input: SpinBox

func _ready() -> void:
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("101925")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _panel_style(Color("29364a")))
	layout.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 18)
	header.add_child(header_row)
	var title := _label("별빛 정원", 28, Color("f4d99a"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	date_label = _label("10살 · 봄 1월", 19, Color("e7e9ef"))
	header_row.add_child(date_label)
	gold_label = _label("금화 420 G", 18, Color("f3ce75"))
	header_row.add_child(gold_label)
	var save_button := _button("저장")
	save_button.pressed.connect(save_game)
	header_row.add_child(save_button)
	var load_button := _button("불러오기")
	load_button.pressed.connect(load_game)
	header_row.add_child(load_button)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	layout.add_child(columns)
	_build_stats_panel(columns)
	_build_schedule_panel(columns)
	_build_story_panel(columns)

	ending_panel = PanelContainer.new()
	ending_panel.add_theme_stylebox_override("panel", _panel_style(Color("3a304b")))
	ending_panel.visible = false
	layout.add_child(ending_panel)
	_build_onboarding()

func _build_onboarding() -> void:
	onboarding_layer = CanvasLayer.new()
	onboarding_layer.layer = 5
	add_child(onboarding_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.075, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	onboarding_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	onboarding_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("29364a")))
	center.add_child(panel)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 12)
	panel.add_child(form)
	form.add_child(_label("새 정원, 새 운명", 25, Color("f4d99a")))
	form.add_child(_label("아이의 이름과 생년월일을 정해주세요. 별자리와 생일 운세가 성장에 작은 힘을 보탭니다.", 14, Color("dce2eb")))
	name_input = LineEdit.new()
	name_input.placeholder_text = "이름 (예: 하린)"
	name_input.text = "하린"
	name_input.max_length = 12
	form.add_child(name_input)
	var date_row := HBoxContainer.new()
	date_row.add_theme_constant_override("separation", 8)
	form.add_child(date_row)
	year_input = _spin_box(1990, 2026, 2012, 90)
	month_input = _spin_box(1, 12, 4, 80)
	day_input = _spin_box(1, 31, 20, 80)
	date_row.add_child(year_input)
	date_row.add_child(_label("년", 14, Color("dce2eb")))
	date_row.add_child(month_input)
	date_row.add_child(_label("월", 14, Color("dce2eb")))
	date_row.add_child(day_input)
	date_row.add_child(_label("일", 14, Color("dce2eb")))
	onboarding_hint = _label("생일 별자리가 초기 능력치와 특정 활동의 보너스를 정합니다.", 13, Color("b9c2d1"))
	onboarding_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(onboarding_hint)
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	form.add_child(button_row)
	var start_button := _button("정원 시작하기")
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.pressed.connect(_start_new_game)
	button_row.add_child(start_button)
	var continue_button := _button("저장 불러오기")
	continue_button.pressed.connect(load_game)
	button_row.add_child(continue_button)

func _spin_box(minimum: int, maximum: int, initial: int, width: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.value = initial
	spin.step = 1
	spin.custom_minimum_size.x = width
	return spin

func _start_new_game() -> void:
	player_name = name_input.text.strip_edges()
	if player_name.is_empty():
		onboarding_hint.text = "이름을 입력해주세요."
		return
	birth_year = int(year_input.value)
	birth_month = int(month_input.value)
	birth_day = int(day_input.value)
	var days_in_month := [31, 29 if _is_leap_year(birth_year) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	if birth_day > int(days_in_month[birth_month - 1]):
		onboarding_hint.text = "입력한 달에 해당 날짜가 없습니다. 날짜를 확인해주세요."
		return
	zodiac = _get_zodiac(birth_month, birth_day)
	fortune_number = _birth_fortune(birth_year, birth_month, birth_day)
	stats[String(zodiac.stat)] = mini(100, int(stats[String(zodiac.stat)]) + 4)
	gold += fortune_number * 5
	month_index = 0
	dungeon_floor = 1
	stardust = 0
	log_lines.clear()
	onboarding_layer.visible = false
	_add_log("%s이(가) %d년 %d월 %d일에 태어났습니다. %s · %s의 기운이 %s에 깃들었습니다." % [player_name, birth_year, birth_month, birth_day, zodiac.name, zodiac.element, zodiac.stat])
	_add_log("생일 운세 %d · 초기 %s +4, 축하 금화 %d G를 받았습니다." % [fortune_number, zodiac.stat, fortune_number * 5])
	_add_log("열 번째 생일을 맞았습니다. 별의 정원에서 새로운 생활을 시작합니다.")
	_refresh()

func _is_leap_year(year: int) -> bool:
	return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

func _get_zodiac(month: int, day: int) -> Dictionary:
	var date_number := month * 100 + day
	if date_number >= 120 and date_number <= 218: return SIGNS[1]
	if date_number >= 219 and date_number <= 320: return SIGNS[2]
	if date_number >= 321 and date_number <= 419: return SIGNS[3]
	if date_number >= 420 and date_number <= 520: return SIGNS[4]
	if date_number >= 521 and date_number <= 620: return SIGNS[5]
	if date_number >= 621 and date_number <= 722: return SIGNS[6]
	if date_number >= 723 and date_number <= 822: return SIGNS[7]
	if date_number >= 823 and date_number <= 922: return SIGNS[8]
	if date_number >= 923 and date_number <= 1022: return SIGNS[9]
	if date_number >= 1023 and date_number <= 1121: return SIGNS[10]
	if date_number >= 1122 and date_number <= 1221: return SIGNS[11]
	return SIGNS[0]

func _birth_fortune(year: int, month: int, day: int) -> int:
	return (year + month * 7 + day * 3) % 9 + 1

func _build_stats_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 250
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("222e40")))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 12)
	content.add_child(identity_row)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/harin.svg") as Texture2D
	portrait.custom_minimum_size = Vector2(74, 82)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	identity_row.add_child(portrait)
	var identity_text := VBoxContainer.new()
	identity_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_text.add_child(_label("정원 식구", 13, Color("b9c2d1")))
	profile_summary_label = _label("하린 · 별자리", 17, Color("f4d99a"))
	profile_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity_text.add_child(profile_summary_label)
	identity_row.add_child(identity_text)
	for key in ["건강", "체력", "지식", "마력", "예술", "매력", "도덕", "스트레스"]:
		var value_label := _label("%s  0" % key, 15, Color("e1e6ef"))
		stat_labels[key] = value_label
		content.add_child(value_label)
	var separator := HSeparator.new()
	content.add_child(separator)
	content.add_child(_label("이번 달 생활비  35 G", 13, Color("b9c2d1")))
	content.add_child(_label("높은 스트레스는 건강을\n해칠 수 있습니다.", 13, Color("d39b91")))

func _build_schedule_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("242f41")))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	content.add_child(_label("이번 달 계획", 22, Color("f4d99a")))
	content.add_child(_label("한 달의 생활을 정하고, 시간이 흐르며 하린의 미래를 함께 만들어 주세요.", 13, Color("bdc6d6")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for key in ACTIONS.keys():
		var action: Dictionary = ACTIONS[key]
		var button := Button.new()
		button.text = "%s\n%s" % [action.title, action.body]
		if key == "adventure":
			button.icon = load("res://assets/dungeon.svg") as Texture2D
			button.expand_icon = true
		button.custom_minimum_size = Vector2(200, 76)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_select_action.bind(String(key)))
		grid.add_child(button)
		action_buttons[key] = button
	selected_label = _label("선택한 계획: 별빛 학원", 15, Color("d9c58e"))
	content.add_child(selected_label)
	var advance_button := _button("한 달 보내기  ›")
	advance_button.custom_minimum_size.y = 48
	advance_button.add_theme_font_size_override("font_size", 18)
	advance_button.pressed.connect(advance_month)
	content.add_child(advance_button)
	var dungeon_hint := _label("던전 층 1 · 별가루 0\n지식과 마력이 높을수록 깊이 공략할 수 있습니다.", 13, Color("a8cde0"))
	dungeon_hint.name = "DungeonHint"
	content.add_child(dungeon_hint)

func _build_story_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 305
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("222e40")))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	content.add_child(_label("정원의 기록", 20, Color("f4d99a")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	log_label = _label("", 14, Color("dce2eb"))
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(log_label)

func _select_action(action_key: String) -> void:
	selected_action = action_key
	_refresh()

func advance_month() -> void:
	if month_index >= 96:
		return
	var action: Dictionary = ACTIONS[selected_action]
	var action_name: String = action.title
	var expense: int = int(action.cost) + 35
	gold -= expense
	if gold < 0:
		gold = 0
		stats["스트레스"] += 7
		_add_log("생활비가 부족해 걱정이 쌓였습니다. 다음 달에는 아르바이트도 고려해 보세요.")
	_apply_action(selected_action)
	if randf() < 0.22:
		_random_event()
	stats["스트레스"] = clampi(int(stats["스트레스"]), 0, 100)
	stats["건강"] = clampi(int(stats["건강"]), 0, 100)
	month_index += 1
	_add_log("%s을(를) 마쳤습니다. 생활비 포함 %d G를 사용했습니다." % [action_name, expense])
	if month_index >= 96:
		_show_ending()
	_refresh()

func _apply_action(action_key: String) -> void:
	match action_key:
		"academy":
			stats["지식"] += 3
			stats["마력"] += 2
			stats["스트레스"] += 8
		"atelier":
			stats["예술"] += 3
			stats["매력"] += 2
			stats["스트레스"] += 6
		"training":
			stats["체력"] += 3
			stats["건강"] += 1
			stats["스트레스"] += 5
		"cafe":
			gold += 105
			stats["매력"] += 2
			stats["스트레스"] += 4
		"farm":
			gold += 80
			stats["체력"] += 1
			stats["도덕"] += 1
			stats["스트레스"] += 3
		"adventure":
			_resolve_adventure()
		"rest":
			stats["건강"] += 10
			stats["스트레스"] -= 14
			stats["매력"] += 1
	if not zodiac.is_empty():
		var affinities: Dictionary = {
			"academy": ["지식", "마력"], "atelier": ["예술", "매력"],
			"training": ["체력", "건강"], "cafe": ["매력"],
			"farm": ["도덕", "체력"], "adventure": ["지식", "마력"], "rest": ["건강"]
		}
		var matching_stats: Array = affinities.get(action_key, [])
		if String(zodiac.stat) in matching_stats:
			stats[String(zodiac.stat)] += 1
			_add_log("%s의 별자리 기운이 맞아 %s +1." % [zodiac.name, zodiac.stat])
	for key in ["건강", "체력", "지식", "마력", "예술", "매력", "도덕"]:
		stats[key] = clampi(int(stats[key]), 0, 100)

func _resolve_adventure() -> void:
	_resolve_dungeon()

func _resolve_dungeon() -> void:
	var floor_number := dungeon_floor
	var challenge := 18 + floor_number * 7
	var knowledge_power := int(stats["지식"]) / 2
	var magic_power := int(stats["마력"])
	var fortune_power := fortune_number if floor_number % 3 == 0 else 0
	var total_power := knowledge_power + magic_power + fortune_power
	_add_log("별의 탑 %d층 · 지식 %d + 마력 %d + 운세 %d = 탐험력 %d / 봉인 난이도 %d" % [floor_number, knowledge_power, magic_power, fortune_power, total_power, challenge])
	if total_power >= challenge:
		var reward := 40 + floor_number * 20 + randi_range(0, 20)
		var dust := 1 + int(floor_number / 3)
		gold += reward
		stardust += dust
		stats["지식"] += 1
		stats["마력"] += 2
		dungeon_floor = mini(20, dungeon_floor + 1)
		_add_log("봉인을 해제하고 %d층으로 진입했습니다! 별가루 %d개와 유물 판매금 %d G를 얻었습니다." % [dust, reward])
		if floor_number == 8:
			_add_log("8층의 별의 정수를 깨웠습니다. 이 경험은 훗날 특별한 진로로 이어질 수 있습니다.")
	else:
		var injury := clampi(4 + int((challenge - total_power) / 5), 4, 16)
		stats["건강"] -= injury
		stats["스트레스"] += 9
		_add_log("봉인이 너무 강해 물러났습니다. 건강 -%d, 스트레스 +9. 학원에서 지식과 마력을 더 키워보세요." % injury)

func _random_event() -> void:
	var event_index: int = randi_range(0, 3)
	match event_index:
		0:
			stats["매력"] += 2
			_add_log("마을 축제에서 친구를 사귀고 자신감을 얻었습니다. 매력 +2.")
		1:
			stats["지식"] += 2
			_add_log("오래된 천문책을 발견했습니다. 지식 +2.")
		2:
			gold += 35
			_add_log("정원 우편함에 후원금 35 G가 도착했습니다.")
		3:
			stats["스트레스"] += 5
			_add_log("예상치 못한 비가 내려 일정이 힘들었습니다. 스트레스 +5.")

func _show_ending() -> void:
	var profession := "마법사"
	var best_score: int = int(stats["마력"])
	if int(stats["체력"]) > best_score:
		profession = "왕실 기사"
		best_score = int(stats["체력"])
	if int(stats["예술"]) > best_score:
		profession = "화가"
		best_score = int(stats["예술"])
	if int(stats["지식"]) > best_score:
		profession = "왕립 학자"
	if int(stats["매력"]) >= 78 and int(stats["도덕"]) >= 60:
		profession = "별빛 외교관"
	if dungeon_floor >= 9 and stardust >= 5:
		profession = "별의 수호자"
	var ending_text := "%s은(는) %s이(가) 되었습니다. 함께 보낸 8년은 두 사람의 마음속에 오래 빛날 거예요." % [player_name, profession]
	ending_panel.add_child(_label("열여덟 살, 새로운 계절", 20, Color("f4d99a")))
	ending_panel.add_child(_label(ending_text, 16, Color("e5e6f0")))
	ending_panel.visible = true
	_add_log("엔딩 · %s" % profession)

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_add_log("저장 파일을 만들지 못했습니다.")
		return
	file.store_string(JSON.stringify({"player_name": player_name, "birth_year": birth_year, "birth_month": birth_month, "birth_day": birth_day, "zodiac": zodiac, "fortune_number": fortune_number, "dungeon_floor": dungeon_floor, "stardust": stardust, "month_index": month_index, "selected_action": selected_action, "gold": gold, "stats": stats, "log_lines": log_lines}))
	_add_log("현재 정원을 저장했습니다.")
	_refresh()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_add_log("저장된 정원이 없습니다.")
		_refresh()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_add_log("저장 파일을 읽을 수 없습니다.")
		return
	var saved: Dictionary = parsed
	player_name = String(saved.get("player_name", "하린"))
	birth_year = int(saved.get("birth_year", 2012))
	birth_month = int(saved.get("birth_month", 4))
	birth_day = int(saved.get("birth_day", 20))
	zodiac = saved.get("zodiac", _get_zodiac(birth_month, birth_day))
	fortune_number = int(saved.get("fortune_number", 1))
	dungeon_floor = clampi(int(saved.get("dungeon_floor", 1)), 1, 20)
	stardust = maxi(0, int(saved.get("stardust", 0)))
	month_index = clampi(int(saved.get("month_index", 0)), 0, 96)
	selected_action = String(saved.get("selected_action", "academy"))
	gold = maxi(0, int(saved.get("gold", 420)))
	var saved_stats: Variant = saved.get("stats", stats)
	if typeof(saved_stats) == TYPE_DICTIONARY:
		stats = saved_stats
	var saved_log: Variant = saved.get("log_lines", [])
	if typeof(saved_log) == TYPE_ARRAY:
		log_lines.assign(saved_log)
	onboarding_layer.visible = false
	_add_log("저장된 정원을 불러왔습니다.")
	if month_index >= 96 and not ending_panel.visible:
		_show_ending()
	_refresh()

func _add_log(text: String) -> void:
	log_lines.append("· " + text)
	while log_lines.size() > 18:
		log_lines.pop_front()
	if log_label:
		log_label.text = "\n\n".join(log_lines)

func _refresh() -> void:
	var age: int = mini(18, 10 + month_index / 12)
	var season_month: int = month_index % 12
	date_label.text = "%d살 · %s" % [age, MONTH_NAMES[season_month]]
	gold_label.text = "금화 %d G" % gold
	if not player_name.is_empty():
		profile_summary_label.text = "%s\n%s · 행운 %d" % [player_name, String(zodiac.get("name", "별자리 미상")), fortune_number]
	var dungeon_hint := find_child("DungeonHint", true, false) as Label
	if dungeon_hint:
		dungeon_hint.text = "던전 층 %d · 별가루 %d\n탐험력: 지식 %d + 마력 %d" % [dungeon_floor, stardust, int(stats["지식"]) / 2, int(stats["마력"])]
	selected_label.text = "선택한 계획: %s" % ACTIONS[selected_action].title
	for key in stat_labels:
		stat_labels[key].text = "%s  %d" % [key, int(stats[key])]
	for key in action_buttons:
		var button: Button = action_buttons[key]
		button.modulate = Color("f2d795") if key == selected_action else Color.WHITE
	log_label.text = "\n\n".join(log_lines)
	if month_index >= 96:
		selected_label.text = "%s의 성장이 끝났습니다. 저장된 기록을 언제든 다시 볼 수 있습니다." % player_name

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 14)
	return button

func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("56657a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
