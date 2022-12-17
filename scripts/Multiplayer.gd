extends Spatial

var peer: NetworkedMultiplayerENet
var capture_effect: AudioEffectCapture
var voice_player = preload("res://VoicePlayer.tscn")
var voip
var login: Node
var my_node
var player_node = preload("res://PlayerPanel.tscn")
var nickname = "server"
var box_container

func _ready():
	login = $Login
	box_container = $Room/PanelContainer/VBoxContainer
	voip = get_node("/root/Voip")

	get_tree().connect("network_peer_connected", self, "client_connected")
	get_tree().connect("connected_to_server", self, "on_connect")
	get_tree().connect("connection_failed", self, "on_connection_failed")
	get_tree().connect("network_peer_disconnected", self, "client_disconnected")

	if not OS.has_feature("Server"):
		var index = AudioServer.get_bus_index("Capture")
		voip.set_bus_index(index)
	else:
		create_server()
		voip.set_server_mode(true)

func create_server():
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(4242, 10)
	get_tree().network_peer = peer
	remove_child(login)
	print("server created")
	on_connect()

func create_client():
	var nickname_text = $Login/LineEdit.text
	if nickname_text.length() == 0:
		return
	nickname = nickname_text
	peer = NetworkedMultiplayerENet.new()
	peer.create_client('127.0.0.1', 4242)
	get_tree().network_peer = peer
	remove_child(login)
	print(nickname)
	
func on_connect():
	print("connected to server")
	var my_id = get_tree().get_network_unique_id()
	var player_instance = player_node.instance()
	player_instance.set_name(str(my_id))
	player_instance.set_network_master(my_id)
	box_container.add_child(player_instance)
	player_instance.rset("nickname", nickname)
	my_node = player_instance

func on_connection_failed():
	add_child(login)

func client_connected(id: int):
	print("client " + str(id) + " connected")
	var player = voice_player.instance()

	if not OS.has_feature("Server"):
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = 16000
		player.stream = stream
		var stream_playback = player.get_stream_playback()
		voip.set_peer_audio_stream_playback(id, stream_playback)

	add_child(player)
	var player_instance = player_node.instance()
	player_instance.set_name(str(id))
	player_instance.set_network_master(id)
	box_container.add_child(player_instance)
	if my_node:
		my_node.rset_id(id, "nickname", nickname)
		my_node.rset_id(id, "muted", voip.get_muted())

func client_disconnected(id: int):
	var node = box_container.get_node(str(id))
	node.queue_free()
	if not OS.has_feature("Server"):
		voip.remove_peer_audio_stream_playback(id)

func toggle_mute():
	var muted = !voip.get_muted()
	voip.set_muted(muted)
	my_node.rset("muted", muted)
