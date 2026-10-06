extends Control

const SAVE_PATH := "user://star_garden_save.json"
const MONTH_NAMES: Array[String] = ["봄 1월", "봄 2월", "봄 3월", "봄 4월", "여름 1월", "여름 2월", "여름 3월", "여름 4월", "가을 1월", "가을 2월", "가을 3월", "가을 4월"]
const ACTIONS: Dictionary = {
	"academy": {"title": "별빛 학원", "body": "지식과 마력을 배웁니다.", "cost": 45},
	"atelier": {"title": "화실 수업", "body": "예술 감각과 매력을 기릅니다.", "cost": 40},
	"training": {"title": "검술 훈련", "body": "체력과 용기를 키웁니다.", "cost": 25},
	"cafe": {"title": "찻집 아르바이트", "body": "생활비를 벌고 사교성을 배웁니다.", "cost": 0},
	"farm": {"title": "약초 농장 일", "body": "성실함과 체력을 기릅니다.", "cost": 0},
	"adventure": {"title": "별숲 탐험", "body": "위험을 감수하고 유물과 경험을 찾습니다.", "cost": 20},
	"rest": {"title": "집에서 휴식", "body": "건강을 회복하고 스트레스를 풉니다.", "cost": 0}
}

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

func _ready() -> void:
	_build_ui()
	_add_log("하린이 열 번째 생일을 맞았습니다. 별의 정원에서 새로운 생활을 시작합니다.")
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

func _build_stats_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 250
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("222e40")))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	content.add_child(_label("하린의 상태", 20, Color("f4d99a")))
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
	for key in ["건강", "체력", "지식", "마력", "예술", "매력", "도덕"]:
		stats[key] = clampi(int(stats[key]), 0, 100)

func _resolve_adventure() -> void:
	var danger: int = randi_range(15, 65)
	var protection: int = int(stats["체력"]) + int(stats["마력"]) / 2
	if protection >= danger:
		var reward: int = randi_range(45, 110)
		gold += reward
		stats["체력"] += 2
		stats["도덕"] += 1
		_add_log("별숲에서 길 잃은 정령을 도왔습니다. 유물 판매금 %d G를 얻었습니다." % reward)
	else:
		stats["건강"] -= 9
		stats["스트레스"] += 10
		_add_log("별숲의 안개 속에서 다쳤습니다. 체력과 준비가 더 필요합니다.")

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
	var ending_text := "하린은 %s이(가) 되었습니다. 함께 보낸 8년은 두 사람의 마음속에 오래 빛날 거예요." % profession
	ending_panel.add_child(_label("열여덟 살, 새로운 계절", 20, Color("f4d99a")))
	ending_panel.add_child(_label(ending_text, 16, Color("e5e6f0")))
	ending_panel.visible = true
	_add_log("엔딩 · %s" % profession)

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_add_log("저장 파일을 만들지 못했습니다.")
		return
	file.store_string(JSON.stringify({"month_index": month_index, "selected_action": selected_action, "gold": gold, "stats": stats, "log_lines": log_lines}))
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
	month_index = clampi(int(saved.get("month_index", 0)), 0, 96)
	selected_action = String(saved.get("selected_action", "academy"))
	gold = maxi(0, int(saved.get("gold", 420)))
	var saved_stats: Variant = saved.get("stats", stats)
	if typeof(saved_stats) == TYPE_DICTIONARY:
		stats = saved_stats
	var saved_log: Variant = saved.get("log_lines", [])
	if typeof(saved_log) == TYPE_ARRAY:
		log_lines.assign(saved_log)
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
	selected_label.text = "선택한 계획: %s" % ACTIONS[selected_action].title
	for key in stat_labels:
		stat_labels[key].text = "%s  %d" % [key, int(stats[key])]
	for key in action_buttons:
		var button: Button = action_buttons[key]
		button.modulate = Color("f2d795") if key == selected_action else Color.WHITE
	log_label.text = "\n\n".join(log_lines)
	if month_index >= 96:
		selected_label.text = "하린의 성장이 끝났습니다. 저장된 기록을 언제든 다시 볼 수 있습니다."

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
