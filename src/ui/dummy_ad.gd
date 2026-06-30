class_name DummyAd
extends CanvasLayer
## A placeholder "rewarded ad": a fake fullscreen ad that counts down, then lets
## the player claim the reward (which skips the level). This is intentionally
## self-contained so it can be swapped for a real ad SDK later — the only contract
## is: call `on_reward` once the reward is granted.
##
## To go live: replace _ready()/_process() with your SDK's rewarded-ad load/show,
## and call `on_reward.call()` from its "user earned reward" callback.

var on_reward := Callable()

const DURATION := 4.0

var _t := DURATION
var _info: Label
var _claim: Button
var _panel: Panel

func _ready() -> void:
	layer = 40

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# "Ad" card.
	_panel = Panel.new()
	_panel.add_theme_stylebox_override("panel", _fake_ad_style())
	_panel.size = Vector2(180, 110)
	_panel.position = Vector2((320 - 180) / 2.0, (180 - 110) / 2.0)
	add_child(_panel)

	var sponsored := UIKit.make_label("ADVERTISEMENT", 7, Color(0, 0, 0, 0.7))
	sponsored.position = Vector2(0, 4)
	sponsored.size = Vector2(180, 10)
	_panel.add_child(sponsored)

	var brand := UIKit.make_label("🎮 PLAY  RAD  RUNNER  🎮", 11, Color(0.1, 0.1, 0.2))
	brand.position = Vector2(0, 34)
	brand.size = Vector2(180, 14)
	_panel.add_child(brand)

	var tagline := UIKit.make_label("(your ad here later)", 7, Color(0.2, 0.2, 0.35))
	tagline.position = Vector2(0, 50)
	tagline.size = Vector2(180, 10)
	_panel.add_child(tagline)

	_info = UIKit.make_label("", 8, Color(0.15, 0.15, 0.25))
	_info.position = Vector2(0, 70)
	_info.size = Vector2(180, 10)
	_panel.add_child(_info)

	_claim = UIKit.make_button("Claim Reward  ▶", 130)
	_claim.position = Vector2((180 - 130) / 2.0, 86)
	_claim.disabled = true
	_claim.pressed.connect(_on_claim)
	_panel.add_child(_claim)

	_refresh()

func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		if _t <= 0.0:
			_claim.disabled = false
			_claim.call_deferred("grab_focus")
			Audio.play("coin")
		_refresh()

func _refresh() -> void:
	if _t > 0.0:
		_info.text = "Reward in %d…" % int(ceil(_t))
	else:
		_info.text = "Thanks for watching!"

func _on_claim() -> void:
	var cb := on_reward
	queue_free()
	if cb.is_valid():
		cb.call()

func _fake_ad_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.95, 0.93, 0.7)
	s.border_color = Color(0.2, 0.2, 0.3)
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	return s
