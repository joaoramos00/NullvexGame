# Cobertura de segredo: rocha (miolo (2,1) do tileset dado) desenhada SOBRE o
# interior de uma área secreta — some quando a parede/gate que a sela quebra
# (o dono conecta o sinal e dá queue_free). Precisa ser um nó próprio com
# z_index alto: coletáveis/elevadores/inimigos são nós irmãos e renderizam
# ACIMA do _draw da stage, então cobrir no _draw da stage não os esconderia.
# Usada nos segredos do stage 01 (passagem Z4, sala do capacete) e stage 02
# (alcovas dos gates de habilidade).

extends Node2D

var tex: Texture2D = null   # cacheada no membro (regra web: nunca load() em _draw)
var rects: Array = []

func _draw() -> void:
	if tex == null:
		return
	const TS := 64.0
	const STS := 32.0
	for r: Rect2 in rects:
		var y := r.position.y
		while y < r.end.y:
			var dh := minf(TS, r.end.y - y)
			var x := r.position.x
			while x < r.end.x:
				var dw := minf(TS, r.end.x - x)
				draw_texture_rect_region(tex, Rect2(x, y, dw, dh),
					Rect2(2.0 * STS, 1.0 * STS, STS * dw / TS, STS * dh / TS))
				x += TS
			y += TS
