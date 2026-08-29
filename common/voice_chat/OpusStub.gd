extends Node

# Passthrough stand-in for the old GDNative opus encoder/decoder nodes until
# the opus GDExtension is integrated. Audio goes over the wire as raw PCM.


func encode(data: PackedByteArray) -> PackedByteArray:
	return data


func decode(data: PackedByteArray) -> PackedByteArray:
	return data
