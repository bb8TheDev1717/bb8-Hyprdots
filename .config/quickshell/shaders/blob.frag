#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float resW;
    float resH;
    float barCx;
    float barCy;
    float barHw;
    float barHh;
    float popupCx;
    float popupCy;
    float popupHw;
    float popupHh;
    float barRadius;
    float popupRadius;
    float smoothFactor;
    vec4 color;
};

float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float radius) {
    vec2 d = abs(p - center) - halfSize + vec2(radius);
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - radius;
}

// Same rounded box, but only the BOTTOM two corners get the radius —
// the top corners stay sharp.
float sdRoundedBoxBottomOnly(vec2 p, vec2 center, vec2 halfSize, float radius) {
    vec2 pp = p - center;
    float r = (pp.y > 0.0) ? radius : 0.0;
    vec2 d = abs(pp) - halfSize + vec2(r);
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - r;
}

// Circular smooth-min (Caelestia's). The blend fillet is a true circular arc of
// radius k, tangent to both surfaces. Crucially it deviates from min(a, b) ONLY
// where BOTH a < k and b < k — i.e. right at the corner — and is exactly min(a, b)
// everywhere else. That locality is what stops the long bar edge from bulging.
float smin(float a, float b, float k) {
    return max(k, min(a, b)) - length(max(vec2(k) - vec2(a, b), vec2(0.0)));
}

void main() {
    vec2 pixel = qt_TexCoord0 * vec2(resW, resH);

    float dBar = sdRoundedBoxBottomOnly(pixel, vec2(barCx, barCy), vec2(barHw, barHh), barRadius);

    // Popup: sharp top corners (the smin fillet handles the junction with the bar),
    // rounded bottom corners.
    vec2 pp = pixel - vec2(popupCx, popupCy);
    float pr = (pp.y > 0.0) ? popupRadius : 0.0;
    vec2 pq = abs(pp) - vec2(popupHw, popupHh) + pr;
    float dPopup = length(max(pq, vec2(0.0))) + min(max(pq.x, pq.y), 0.0) - pr;

    // Concave fillet at the two inner corners where popup walls meet the bar bottom.
    // Circular smin only bends the corner region; the rest of the bar stays flat.
    float d = smin(dBar, dPopup, smoothFactor);

    float fw = fwidth(d);
    float shape = 1.0 - smoothstep(-fw, fw, d);
    float alpha = shape * color.a;
    fragColor = vec4(color.rgb * alpha, alpha) * qt_Opacity;
}
