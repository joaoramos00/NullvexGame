// Lava em movimento: escorre na horizontal + ondula a superfície. Aplicado nos
// sprites tilados da maré de lava (textura do PixelLab).
shader_type canvas_item;

uniform float scroll_speed : hint_range(0.0, 1.0) = 0.12;  // velocidade do fluxo lateral
uniform float wave_amp     : hint_range(0.0, 0.1) = 0.012;  // amplitude da ondulação
uniform float wave_freq    : hint_range(0.0, 30.0) = 10.0;  // frequência da ondulação
uniform float wave_speed   : hint_range(0.0, 6.0) = 1.6;    // velocidade da onda

void fragment() {
	vec2 uv = UV;
	uv.x += TIME * scroll_speed;
	uv.y += sin(uv.x * wave_freq + TIME * wave_speed) * wave_amp;
	COLOR = texture(TEXTURE, uv);
}
