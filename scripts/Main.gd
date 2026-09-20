extends Control

@onready var night_label = $HUD/NightLabel
@onready var power_label = $HUD/PowerLabel
@onready var status_label = $HUD/StatusLabel
@onready var phone_label = $HUD/PhonePanel/PhoneText
@onready var camera_label = $HUD/CameraPanel/CameraLabel
@onready var camera_panel = $HUD/CameraPanel
@onready var left_door = $Office/LeftDoor
@onready var right_door = $Office/RightDoor
@onready var left_door_label = $HUD/LeftDoorLabel
@onready var right_door_label = $HUD/RightDoorLabel

const TOTAL_NIGHT_TIME := 360.0
const ROOM_NAMES := ["Stage", "Dining", "Backstage", "West Hall", "Left Hall", "Right Hall", "Office"]

var elapsed_time := 0.0
var power := 100.0
var left_door_closed := false
var right_door_closed := false
var camera_active := false
var camera_index := 0
var phone_index := 0

var phone_calls := [
    {"time": 15.0, "text": "Hello? This is the phone guy. Night 1. Keep the doors closed and watch the halls."},
    {"time": 110.0, "text": "Be careful on the left side. Bonnie tends to move early on."},
    {"time": 190.0, "text": "Chica may come from the right. Do not ignore the door."},
    {"time": 260.0, "text": "Foxy is getting bolder. Keep the right side guarded if you hear footsteps."},
    {"time": 315.0, "text": "Final hour. Hold until 6 AM. Stay calm and do not panic."}
]

var animatronics := [
    {"name": "Bonnie", "door": "left", "position": 0, "progress": 0.0, "speed": 0.56},
    {"name": "Chica", "door": "right", "position": 0, "progress": 0.0, "speed": 0.52},
    {"name": "Freddy", "door": "right", "position": 0, "progress": 0.0, "speed": 0.42},
    {"name": "Foxy", "door": "left", "position": 0, "progress": 0.0, "speed": 0.66}
]

var game_over := false
var victory := false

func _ready() -> void:
    _update_ui()
    phone_label.text = "Phone: No call yet."
    status_label.text = "Status: Night 1 has started"

func _process(delta: float) -> void:
    if game_over or victory:
        return

    elapsed_time += delta
    _handle_phone_calls()
    _advance_animatronics(delta)
    _update_power(delta)
    _update_clock()
    _update_ui()

    if elapsed_time >= TOTAL_NIGHT_TIME:
        victory = true
        status_label.text = "Status: 6 AM reached. You survived the night."
        return

func _update_clock() -> void:
    var hour_index := int(elapsed_time / 60.0)
    if hour_index > 6:
        hour_index = 6
    var displayed_hour = [12, 1, 2, 3, 4, 5, 6][hour_index]
    night_label.text = str(displayed_hour) + " AM"

func _handle_phone_calls() -> void:
    if phone_index >= phone_calls.size():
        return

    var call = phone_calls[phone_index]
    if elapsed_time >= call["time"]:
        phone_label.text = "Phone: " + str(call["text"])
        phone_index += 1

func _update_power(delta: float) -> void:
    var drain := 1.6
    if camera_active:
        drain += 1.2
    if left_door_closed:
        drain += 0.8
    if right_door_closed:
        drain += 0.8

    power = max(0.0, power - drain * delta)
    power_label.text = "Power: %d%%" % int(power)

    if power <= 0.0:
        _trigger_game_over("Power drained. The office went dark.")

func _advance_animatronics(delta: float) -> void:
    var pressure := elapsed_time / TOTAL_NIGHT_TIME

    for anim in animatronics:
        var name_text = str(anim["name"])
        anim["progress"] = float(anim["progress"]) + delta * (float(anim["speed"]) + pressure * 1.5)

        while anim["progress"] >= 1.0:
            anim["progress"] -= 1.0
            anim["position"] += 1

            if anim["position"] >= ROOM_NAMES.size() - 1:
                anim["position"] = ROOM_NAMES.size() - 1
                if anim["door"] == "left" and not left_door_closed:
                    _trigger_game_over(name_text + " slipped past the left door.")
                    return
                elif anim["door"] == "right" and not right_door_closed:
                    _trigger_game_over(name_text + " slipped past the right door.")
                    return
                else:
                    status_label.text = name_text + " is at the door, but it is closed."
                break

func _update_ui() -> void:
    var left_state = "OPEN" if not left_door_closed else "CLOSED"
    var right_state = "OPEN" if not right_door_closed else "CLOSED"
    left_door_label.text = "Left Door: " + left_state
    right_door_label.text = "Right Door: " + right_state

    if left_door_closed:
        left_door.color = Color(0.85, 0.9, 1.0, 1.0)
    else:
        left_door.color = Color(0.18, 0.18, 0.2, 1.0)

    if right_door_closed:
        right_door.color = Color(0.85, 0.9, 1.0, 1.0)
    else:
        right_door.color = Color(0.18, 0.18, 0.2, 1.0)

    camera_panel.visible = camera_active
    if camera_active:
        camera_label.text = "Camera: " + ROOM_NAMES[camera_index]
    else:
        camera_label.text = "Camera: Off"

func _unhandled_input(event: InputEvent) -> void:
    if game_over or victory:
        return

    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_A:
                left_door_closed = !left_door_closed
                status_label.text = "Left door %s" % ("closed" if left_door_closed else "opened")
                _update_ui()
            KEY_D:
                right_door_closed = !right_door_closed
                status_label.text = "Right door %s" % ("closed" if right_door_closed else "opened")
                _update_ui()
            KEY_C:
                camera_active = !camera_active
                if camera_active:
                    status_label.text = "Camera feed opened"
                else:
                    status_label.text = "Camera feed closed"
                _update_ui()
            KEY_Q:
                camera_index = wrapi(camera_index - 1, 0, ROOM_NAMES.size())
                if camera_active:
                    _update_ui()
            KEY_E:
                camera_index = wrapi(camera_index + 1, 0, ROOM_NAMES.size())
                if camera_active:
                    _update_ui()

func _trigger_game_over(message: String) -> void:
    game_over = true
    status_label.text = "Status: " + message
    phone_label.text = "Phone: The office has failed."
