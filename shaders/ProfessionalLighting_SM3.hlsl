// ProfessionalLighting_SM3 (DX9 / MPC-BE)
// Shader Model 3.0 — maximum quality ambient lighting profile.

// ============================================================
//  USER TWEAKABLES — safe to edit freely
//  All perceptually meaningful controls in one place.
// ============================================================

// --- Color grading ---
#define GRADE_VIBRANCE_NEAR     1.42
#define GRADE_VIBRANCE_FAR      1.20
#define GRADE_GAIN_NEAR         1.52
#define GRADE_GAIN_FAR          1.22
#define GRADE_SAT_LIMIT_NEAR    0.74
#define GRADE_SAT_LIMIT_FAR     0.56
#define GRADE_FINAL_BRIGHT_NEAR 1.02
#define GRADE_FINAL_BRIGHT_FAR  0.74

// --- Light falloff ---
#define FADE_DECAY_RATE         2.2
#define FADE_FLOOR_LIGHT        0.18
#define FADE_FLOOR_DARK         0.10

// --- Warm halation ---
#define HALATION_AMOUNT_BASE    0.025
#define HALATION_AMOUNT_FAR     0.018
#define HALATION_DARK_SUPPRESS  0.45

// --- Analog effects ---
#define VIGNETTE_BLEND          0.40
#define VERT_GRAD_AMOUNT        0.38
#define CHROMA_ABERR_AMOUNT     0.10
#define LENS_DIRT_AMOUNT        0.016

// --- Effect toggles (1 = enabled, 0 = disabled) ---
#define ENABLE_VIGNETTE         1
#define ENABLE_VERT_GRADIENT    1
#define ENABLE_CHROMA_ABERR     1
#define ENABLE_LENS_DIRT        1
#define ENABLE_WARM_HALATION    1
#define ENABLE_TPDF_DITHER      1

// ============================================================
//  END OF USER TWEAKABLES
// ============================================================

sampler s0 : register(s0);
float4 p0 : register(c0); // p0.x = width, p0.y = height

// Guard against broken/zero frame-size constants from renderer state changes
// (e.g. fullscreen/pause transitions). Keep math stable without touching detector logic.
#define width  (max(p0.x, 16.0))
#define height (max(p0.y, 16.0))
#define invW   (1.0 / width)
#define invH   (1.0 / height)

// Detection / blending
#define darkThreshold (0.085)
#define hardBandSide  (0.0024)
#define hardBandTB    (0.0028)
// Detector stability rule:
// Do not radically alter detector topology/branches.
// Allowed changes: only small threshold tuning and minor border probe refinements.

// Aspect defaults
#define sideBorderBase (0.125)
#define topBorderBase  (0.125)

float Luma(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}

float2 SafeUV(float2 uv)
{
    // Keep clamp interval valid even if incoming dimensions are temporarily bad.
    float2 m = min(float2(2.0 * invW, 2.0 * invH), 0.49);
    return clamp(uv, m, 1.0 - m);
}

float3 SampleRGB(float2 uv)
{
    return tex2D(s0, SafeUV(uv)).rgb;
}

float IsDarkAt(float2 uv)
{
    return (Luma(SampleRGB(uv)) < darkThreshold) ? 1.0 : 0.0;
}

float IsDarkColumn(float x)
{
    float a = IsDarkAt(float2(x, 0.20));
    float b = IsDarkAt(float2(x, 0.50));
    float c = IsDarkAt(float2(x, 0.75));
    return (a + b + c) / 3.0;
}

float IsDarkRow(float y)
{
    float a = IsDarkAt(float2(0.20, y));
    float b = IsDarkAt(float2(0.50, y));
    float c = IsDarkAt(float2(0.75, y));
    return (a + b + c) / 3.0;
}

float Hash12(float2 p)
{
    float h = dot(p, float2(127.1, 311.7));
    return frac(sin(h) * 43758.5453123);
}

float3 BlurAniso9(float2 uv, float rxPx, float ryPx)
{
    float2 rx = float2(rxPx * invW, 0.0);
    float2 ry = float2(0.0, ryPx * invH);
    float2 d1 = rx + ry;
    float2 d2 = rx - ry;

    float3 c = SampleRGB(uv) * 4.0;
    c += SampleRGB(uv + rx) * 2.0;
    c += SampleRGB(uv - rx) * 2.0;
    c += SampleRGB(uv + ry) * 2.0;
    c += SampleRGB(uv - ry) * 2.0;
    c += SampleRGB(uv + d1);
    c += SampleRGB(uv - d1);
    c += SampleRGB(uv + d2);
    c += SampleRGB(uv - d2);
    return c * (1.0 / 16.0);
}

float3 BlurAniso13(float2 uv, float rxPx, float ryPx)
{
    float2 rx = float2(rxPx * invW, 0.0);
    float2 ry = float2(0.0, ryPx * invH);
    float2 rx2 = rx * 2.0;
    float2 ry2 = ry * 2.0;
    float2 d1 = rx + ry;
    float2 d2 = rx - ry;

    float3 c = SampleRGB(uv) * 4.0;
    c += (SampleRGB(uv + rx) + SampleRGB(uv - rx)) * 1.8;
    c += (SampleRGB(uv + ry) + SampleRGB(uv - ry)) * 1.8;
    c += (SampleRGB(uv + d1) + SampleRGB(uv - d1) + SampleRGB(uv + d2) + SampleRGB(uv - d2)) * 1.3;
    c += (SampleRGB(uv + rx2) + SampleRGB(uv - rx2)) * 0.8;
    c += (SampleRGB(uv + ry2) + SampleRGB(uv - ry2)) * 0.8;
    return c * (1.0 / 19.6);
}

float3 Filmic(float3 c)
{
    c = max(c, 0.0);
    c = (c * (2.51 * c + 0.03)) / (c * (2.43 * c + 0.59) + 0.14);
    return saturate(c);
}

float Chroma(float3 c)
{
    float mx = max(c.r, max(c.g, c.b));
    float mn = min(c.r, min(c.g, c.b));
    return mx - mn;
}

float ColorDelta(float3 a, float3 b)
{
    return Luma(abs(a - b));
}

float3 SaturationLimit(float3 col, float maxSat)
{
    float lum = Luma(col);
    float3 d = col - lum.xxx;
    float sat = Chroma(col); // perceptual chroma (max-min), not euclidean length
    float k = min(1.0, maxSat / max(sat, 1e-4)); // branchless — same as L11 ArtifactGuard fix
    return lum.xxx + d * k;
}

float3 SatGuard(float3 col, float3 edgeRef, float n)
{
    float refSat = Chroma(edgeRef);
    float satCap = lerp(refSat * 1.60 + 0.14, refSat * 1.26 + 0.09, n);
    satCap = clamp(satCap, 0.32, 0.92);
    return SaturationLimit(col, satCap);
}

float3 MidContrast(float3 col, float amount)
{
    float3 p = Luma(col).xxx;
    return p + (col - p) * (1.0 + amount);
}

float3 CleanEdgeColor(float3 c0, float3 c1, float3 c2, float3 c3, float3 c4)
{
    float3 mixC = c0 * 0.34 + (c1 + c2) * 0.21 + (c3 + c4) * 0.12;
    float3 nb = (c1 + c2) * 0.5;
    float lum = Luma(mixC);
    float sat = Chroma(mixC);
    float jump = ColorDelta(c0, nb);
    float spike = saturate((sat - 0.26) / 0.30) * saturate((jump - 0.05) / 0.16);
    mixC = lerp(mixC, lum.xxx, spike * 0.62);
    return mixC;
}

float3 VibranceBoost(float3 col, float strength)
{
    // SweetFX / CeeJay.dk formula: chroma-dependent scaling
    // Already-vivid colors are barely touched; muted areas get full boost.
    // sign(strength) handles negative vibrance (desaturation) correctly.
    float lum = Luma(col);
    float chroma = Chroma(col);
    return lerp(lum.xxx, col, 1.0 + strength * (1.0 - chroma)); // sign() removed — strength always > 0 here
}

float3 WarmHalation(float3 baseCol, float3 glowCol, float amount)
{
    // Physically accurate film halation: warm red-orange tint, tight to bright edges only.
    // Distinct from bloom (which is neutral/cool and wide).
    // Color: float3(1.0, 0.18, 0.02) matches red-layer bleed on real film stock.
    float h = smoothstep(0.18, 0.85, Luma(glowCol));
    float3 tint = float3(1.00, 0.08, 0.01);
    return baseCol + glowCol * tint * (amount * h);
}

float MirrorMask(float n)
{
    float rise = smoothstep(0.06, 0.48, n);
    float fall = 1.0 - smoothstep(0.92, 1.0, n);
    return rise * fall;
}

float3 EdgePaletteSide(float edgeX, float dir, float yCenter, float n)
{
    float y1 = 0.030 + 0.050 * n;
    float y2 = 0.070 + 0.100 * n;
    float y3 = 0.110 + 0.140 * n;
    float d0 = 0.014;
    float d1 = 0.042 + 0.050 * n;
    float d2 = 0.090 + 0.110 * n;
    float d3 = 0.150 + 0.180 * n;

    float3 c0 = SampleRGB(float2(saturate(edgeX + dir * d0), yCenter));
    float3 c1 = SampleRGB(float2(saturate(edgeX + dir * d1), clamp(yCenter + y1, 0.06, 0.94)));
    float3 c2 = SampleRGB(float2(saturate(edgeX + dir * d1), clamp(yCenter - y1, 0.06, 0.94)));
    float3 c3 = SampleRGB(float2(saturate(edgeX + dir * d2), clamp(yCenter + y2, 0.06, 0.94)));
    float3 c4 = SampleRGB(float2(saturate(edgeX + dir * d2), clamp(yCenter - y2, 0.06, 0.94)));
    float3 c5 = SampleRGB(float2(saturate(edgeX + dir * d3), clamp(yCenter + y3, 0.06, 0.94)));
    float3 c6 = SampleRGB(float2(saturate(edgeX + dir * d3), clamp(yCenter - y3, 0.06, 0.94)));
    float3 c7 = SampleRGB(float2(saturate(edgeX + dir * d2), 1.0 - yCenter));
    float3 c8 = SampleRGB(float2(saturate(edgeX + dir * d2), 0.22));
    float3 c9 = SampleRGB(float2(saturate(edgeX + dir * d2), 0.78));

    float oppW = 0.03 + 0.05 * (1.0 - saturate(ColorDelta(c0, c7) / 0.28));
    float3 col = c0 * 0.26 +
                 (c1 + c2) * 0.13 +
                 (c3 + c4) * 0.10 +
                 (c5 + c6) * 0.06 +
                 c8 * 0.07 +
                 c9 * 0.07 +
                 c7 * oppW;
    return col;
}

float3 EdgePaletteTop(float edgeY, float dir, float xCenter, float n)
{
    float x1 = 0.030 + 0.050 * n;
    float x2 = 0.070 + 0.100 * n;
    float x3 = 0.110 + 0.140 * n;
    float d0 = 0.014;
    float d1 = 0.042 + 0.050 * n;
    float d2 = 0.090 + 0.110 * n;
    float d3 = 0.150 + 0.180 * n;

    float3 c0 = SampleRGB(float2(xCenter, saturate(edgeY + dir * d0)));
    float3 c1 = SampleRGB(float2(clamp(xCenter + x1, 0.06, 0.94), saturate(edgeY + dir * d1)));
    float3 c2 = SampleRGB(float2(clamp(xCenter - x1, 0.06, 0.94), saturate(edgeY + dir * d1)));
    float3 c3 = SampleRGB(float2(clamp(xCenter + x2, 0.06, 0.94), saturate(edgeY + dir * d2)));
    float3 c4 = SampleRGB(float2(clamp(xCenter - x2, 0.06, 0.94), saturate(edgeY + dir * d2)));
    float3 c5 = SampleRGB(float2(clamp(xCenter + x3, 0.06, 0.94), saturate(edgeY + dir * d3)));
    float3 c6 = SampleRGB(float2(clamp(xCenter - x3, 0.06, 0.94), saturate(edgeY + dir * d3)));
    float3 c7 = SampleRGB(float2(1.0 - xCenter, saturate(edgeY + dir * d2)));
    float3 c8 = SampleRGB(float2(0.22, saturate(edgeY + dir * d2)));
    float3 c9 = SampleRGB(float2(0.78, saturate(edgeY + dir * d2)));

    float oppW = 0.03 + 0.05 * (1.0 - saturate(ColorDelta(c0, c7) / 0.28));
    float3 col = c0 * 0.26 +
                 (c1 + c2) * 0.13 +
                 (c3 + c4) * 0.10 +
                 (c5 + c6) * 0.06 +
                 c8 * 0.07 +
                 c9 * 0.07 +
                 c7 * oppW;
    return col;
}

float3 BlendSoftLight(float3 base, float3 blend)
{
    // Photoshop/film soft-light blend: organic, non-linear seam transition
    float3 a = 2.0 * base * blend + base * base * (1.0 - 2.0 * blend);
    float3 b = sqrt(max(base, 1e-4)) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend);
    return lerp(a, b, step(0.5, blend));
}

float3 GradeAmbientSM3(float3 col, float n, float edgeLum)
{
    float3 srcCol = col;
    float lum = Luma(col);
    float shadowScene = saturate((0.24 - edgeLum) / 0.24);
    float desat = lerp(0.015, 0.085, n);
    desat += shadowScene * lerp(0.020, 0.055, n);
    col = lerp(col, lum.xxx, desat);

    // Stronger cinematic vibrance in near-edge area.
    // Recalculate lum after desaturation so vibrance pivots on current value.
    float lumVib = Luma(col);
    float vib = lerp(1.42, 1.20, n);
    vib *= (1.0 - 0.14 * shadowScene);
    col = lerp(lumVib.xxx, col, vib);
    col = VibranceBoost(col, lerp(0.50, 0.20, n) * (1.0 - 0.20 * shadowScene));

    float3 coolA = float3(1.01, 1.02, 1.04); // было (1.01, 1.05, 1.11) — B=1.11 давал синий сдвиг на серых/коричневых
    float3 coolB = float3(1.01, 1.01, 1.02); // было (1.01, 1.03, 1.06)
    float3 cool = lerp(coolA, coolB, shadowScene);
    float3 warm = float3(1.04, 1.01, 1.00); // было 1.07/1.03/0.99 → 1.15/1.08/0.98 — "коричневое стекло"
    float w = saturate((edgeLum - 0.38) / 0.44); // было 0.26 — warm активировался слишком рано (полутёмные сцены)
    float split = smoothstep(0.08, 0.84, lum);
    col *= lerp(cool, warm, saturate(0.46 * split + 0.36 * w)); // было 0.55/0.45 — давало "коричневое стекло"

    float gain = lerp(GRADE_GAIN_NEAR, GRADE_GAIN_FAR, n);
    gain *= (1.0 - 0.11 * shadowScene);
    col *= gain;

    float bloom = smoothstep(0.28, 0.92, Luma(col));
    col += bloom * (0.010 + 0.014 * (1.0 - n));
    col += smoothstep(0.08, 0.66, lum) * (0.006 + 0.006 * (1.0 - n));
    col += (0.006 + 0.010 * n);

    // Mid-tone clarity and gentle shoulder control.
    float3 pivot = Luma(col).xxx;
    float clarity = lerp(1.14, 1.06, n);
    col = pivot + (col - pivot) * clarity;

    // Preserve source hue relation while staying vivid.
    col = lerp(srcCol, col, lerp(0.90, 0.82, n)); // было 0.97/0.90 — grading слишком агрессивно перебивал исходный цвет

    // Keep cinematic saturation but prevent broken neon artifacts.
    col = SaturationLimit(col, lerp(GRADE_SAT_LIMIT_NEAR, GRADE_SAT_LIMIT_FAR, n) * (1.0 - 0.12 * shadowScene));
    col = lerp(Luma(col).xxx, col, lerp(1.10, 1.03, n));

    float g = lerp(0.92, 1.00, n);
    col = pow(max(col, 1e-4), g.xxx);

    // Darker outer ambient, brighter near the frame edge.
    col *= lerp(GRADE_FINAL_BRIGHT_NEAR, GRADE_FINAL_BRIGHT_FAR, n);
    // Hard saturation cap before Filmic: prevents gain from whitening saturated colors (yellow→white).
    col = SaturationLimit(col, lerp(0.68, 0.50, n));
    col = Filmic(col); // single filmic compressor; SoftClip removed (duplicate)
    return saturate(col);
}

float3 ArtifactGuardSM3(float3 col, float edgeLum, float darkScene, float streakRisk)
{
    // Suppress dark-scene color spikes and vertical streak flashes while preserving richness.
    float guard = saturate(0.55 * darkScene + 0.30 * streakRisk);
    col = SaturationLimit(col, lerp(0.70, 0.48, guard));
    col = lerp(Luma(col).xxx, col, lerp(1.05, 0.92, guard));

    float lum = Luma(col);
    float lumCap = edgeLum + lerp(0.20, 0.10, guard);
    col *= min(1.0, lumCap / max(lum, 1e-4));
    return col;
}

// Vignette: smooth dark corners, aspect-correct, zero ALU texture samples
float Vignette(float2 uv)
{
    float2 tc = (uv - 0.5) * float2(width / max(height, 1.0), 1.0);
    float v = dot(tc, tc);
    return saturate(1.0 - pow(v, 3.0) * 0.55);
}

// VerticalGradient: top of ambient zone is slightly darker than bottom.
// Mimics cinema hall downward lighting — zero texture samples.
// amount: how much darker the top edge gets (0=off, 1=fully black at top).
float VerticalGradient(float2 uv, float amount)
{
    // uv.y=0 is top, uv.y=1 is bottom.
    // We want top darker: multiply by something < 1 when uv.y is small.
    float t = 1.0 - saturate(amount * (1.0 - uv.y) * 0.55);
    return t;
}

// LensDirt: procedural dust/smear on lens — brightens highlights at random spots.
// Zero texture samples — pure ALU hash pattern.
// strength: max brightness boost from dust (keep very low, ~0.012-0.020).
float3 LensDirt(float3 col, float2 uv, float strength)
{
    // Multi-octave hash: coarse blobs + fine grain
    float h1 = Hash12(floor(uv * float2(width, height) * 0.018));
    float h2 = Hash12(floor(uv * float2(width, height) * 0.055) + 7.3);
    float dirt = h1 * 0.65 + h2 * 0.35;
    // Only show dirt where the ambient color is already bright (highlights)
    float lum = Luma(col);
    float mask = smoothstep(0.28, 0.72, lum) * smoothstep(0.50, 0.90, dirt);
    return col + col * (mask * strength);
}

// ChromaticAberration: lateral R/B channel shift toward corners.
// Zero texture samples — operates on already-computed color value.
// strength: maximum channel offset as fraction of the zone width.
float3 ChromaticAberration(float3 col, float2 uv, float strength)
{
    // Radial distance from center, aspect-correct
    float2 tc = (uv - 0.5) * float2(width / max(height, 1.0), 1.0);
    float r2 = dot(tc, tc);
    float shift = strength * r2; // grows quadratically toward corners

    // Approximate channel split: push R toward red, B toward blue.
    // Since we can't re-sample here, simulate with a luma-based gradient.
    float lum = Luma(col);
    float3 warm = float3(1.0, 0.0, -1.0); // R up, B down
    return saturate(col + warm * (lum * shift * 0.60));
}

float3 BuildSideFillSM3(float2 tex, float xBorder)
{
    bool leftSide = (tex.x < xBorder);
    float edgeX = leftSide ? xBorder : (1.0 - xBorder);
    float d = leftSide ? (xBorder - tex.x) : (tex.x - (1.0 - xBorder));
    float n = saturate(d / max(xBorder, 1e-4));
    float dir = leftSide ? 1.0 : -1.0;

    float ySafe = clamp(tex.y, 0.08, 0.92);
    float yAnchor = lerp(ySafe, 0.5, 0.28 + 0.22 * n);
    float xWarp = (Hash12(float2(ySafe * height * 0.37 + n * 17.0, edgeX * 991.0)) - 0.5) * (0.45 * invW);

    float2 uvNear = float2(
        saturate(edgeX + dir * (0.016 + 0.052 * n) + xWarp),
        saturate(lerp(ySafe, yAnchor, 0.36))
    );
    float2 uvMid = float2(
        saturate(edgeX + dir * (0.070 + 0.128 * n) + xWarp),
        saturate(lerp(ySafe, yAnchor, 0.70))
    );
    float2 uvFar = float2(
        saturate(edgeX + dir * (0.138 + 0.214 * n) + xWarp),
        saturate(lerp(ySafe, 0.5, 0.82))
    );

    float3 cNear = BlurAniso13(uvNear, 4.8 + 7.6 * n, 8.6 + 14.5 * n);
    float3 cMid = BlurAniso13(uvMid, 6.8 + 10.8 * n, 12.8 + 20.8 * n);
    float3 cFar = BlurAniso9(uvFar, 10.6 + 15.8 * n, 17.0 + 25.0 * n);
    float3 col = cNear * 0.45 + cMid * 0.34 + cFar * 0.21;
    float3 sweep = BlurAniso9(float2(uvMid.x, yAnchor), 4.0 + 6.4 * n, 16.0 + 24.0 * n);
    col = lerp(col, sweep, 0.05 + 0.07 * n);

    float yMirror = 1.0 - ySafe;
    float2 muv = float2(
        saturate(edgeX + dir * (0.058 + 0.174 * n) + xWarp * 0.60),
        saturate(lerp(yMirror, yAnchor, 0.30))
    );
    float3 mirrorCol = BlurAniso9(muv, 4.8 + 8.0 * n, 9.4 + 15.5 * n);
    mirrorCol = SaturationLimit(mirrorCol, 0.78);
    mirrorCol = lerp(Luma(mirrorCol).xxx, mirrorCol, 1.06);

    // Multi-depth edge sampling (Hyperion/Prismatik approach):
    // Near edge has compression ringing — weight deeper samples more for cleaner color.
    float2 edgeUV = float2(saturate(edgeX + dir * (2.0 * invW)), ySafe);
    float2 edgeUV2 = float2(saturate(edgeX + dir * (4.0 * invW)), ySafe);
    float2 edgeUV3 = float2(saturate(edgeX + dir * (8.0 * invW)), ySafe);
    float3 eDepth1 = BlurAniso9(edgeUV,  2.2, 6.8);
    float3 eDepth2 = BlurAniso9(edgeUV2, 3.0, 7.5);
    float3 eDepth3 = BlurAniso9(edgeUV3, 3.5, 8.5);
    float3 edge0 = eDepth1 * 0.25 + eDepth2 * 0.45 + eDepth3 * 0.30;
    float yStep = (4.0 + 6.0 * n) * invH;
    float3 edgeUp = SampleRGB(edgeUV2 + float2(0.0, yStep));
    float3 edgeDn = SampleRGB(edgeUV2 - float2(0.0, yStep));
    float3 edgeIn = BlurAniso9(float2(saturate(edgeX + dir * (8.0 * invW)), yAnchor), 2.8, 8.3);
    float3 edgeSoft = CleanEdgeColor(edge0, edgeUp, edgeDn, edgeIn, mirrorCol);
    float edgeLum = Luma(edgeSoft);
    float darkScene = saturate((0.24 - edgeLum) / 0.24);
    float darkSuppress = saturate(1.0 - 1.35 * darkScene);

    float3 palette = EdgePaletteSide(edgeX, dir, yAnchor, n);
    palette = SaturationLimit(palette, 0.86);

    float streakRisk = saturate((ColorDelta(edgeUp, edgeDn) - 0.06) / 0.22);
    float paletteAmt = 0.03 + 0.08 * n + 0.06 * streakRisk;
    float mirrorAmt = (0.02 + 0.05 * MirrorMask(n)) * (1.0 - 0.65 * streakRisk);
    paletteAmt *= darkSuppress;
    mirrorAmt *= darkSuppress;

    col = lerp(col, palette, paletteAmt);
    col = lerp(col, mirrorCol, mirrorAmt);

    float3 spread = BlurAniso13(float2(uvMid.x, yAnchor), 12.0 + 17.0 * n, 15.0 + 22.0 * n);
    float spreadAmt = saturate(0.22 + 0.16 * n + 0.24 * streakRisk);
    col = lerp(col, spread, spreadAmt);

    float shadowLock = saturate(0.24 + 0.62 * darkScene + 0.32 * streakRisk);
    float3 stableRef = lerp(edgeSoft, palette, 0.30);
    float stableAmt = shadowLock * (0.10 + 0.06 * n) * (0.35 + 0.65 * darkSuppress);
    col = lerp(col, stableRef, stableAmt);

    float edgeBoost = (1.0 - smoothstep(0.22, 0.86, n));
    col = lerp(col, MidContrast(col, 0.11), edgeBoost * 0.54);
    col = SatGuard(col, lerp(edgeSoft, palette, 0.48), n);
    float seam = smoothstep(0.002, 0.065, n);
    float rim = (1.0 - smoothstep(0.0, 0.032, n));
    // Soft-light blend at seam: organic film-like transition instead of hard lerp
    col = lerp(edgeSoft, BlendSoftLight(edgeSoft, col), seam);
    float rimAmt = rim * (1.0 - 0.90 * darkScene);
    col += edgeSoft * (0.0025 * rimAmt) + edgeLum.xxx * (0.0009 * rimAmt);

    float glowAmt = 0.050 * (1.0 - n) * (0.65 + 0.35 * saturate(edgeLum * 1.2));
    col = 1.0 - (1.0 - col) * (1.0 - edgeSoft * glowAmt);

    col = GradeAmbientSM3(col, n, edgeLum);
    col *= lerp(float3(0.99, 1.00, 1.02), float3(1.02, 1.00, 0.99), tex.y);
#if ENABLE_WARM_HALATION
    col = WarmHalation(col, edgeSoft, (HALATION_AMOUNT_BASE + HALATION_AMOUNT_FAR * (1.0 - n)) * (1.0 - HALATION_DARK_SUPPRESS * darkScene));
#endif
    col = ArtifactGuardSM3(col, edgeLum, darkScene, streakRisk);
    float darkSafe = saturate((darkScene - 0.16) / 0.44);
    float3 safeBlur = BlurAniso13(float2(uvMid.x, yAnchor), 8.0 + 10.0 * n, 8.0 + 10.0 * n);
    safeBlur = GradeAmbientSM3(safeBlur, n, edgeLum);
    safeBlur = ArtifactGuardSM3(safeBlur, edgeLum, darkScene, streakRisk);
    col = lerp(col, safeBlur, darkSafe * (0.80 + 0.20 * streakRisk));
    float brightSafe = saturate((edgeLum - 0.26) / 0.40) * (0.10 + 0.18 * streakRisk); // было 0.18+0.24 — тянуло к нейтральному safeBlur, убивало голубой
    col = lerp(col, safeBlur, brightSafe);
    col = SaturationLimit(col, lerp(0.54, 0.34, darkScene));
    col *= (1.0 - 0.07 * saturate(1.0 - n * 14.0));

    // Exponential fade — perceptually closer to real light falloff than pow()
    float fadeFloor = lerp(FADE_FLOOR_LIGHT, FADE_FLOOR_DARK, darkScene);
    float fadeN = smoothstep(0.0, 0.06, n); // soft entry at seam — no hard pop at n=0
    float fade = max(fadeFloor, exp(-n * FADE_DECAY_RATE)) * fadeN;
    col *= fade;

#if ENABLE_VIGNETTE
    col *= lerp(1.0, Vignette(tex), VIGNETTE_BLEND);
#endif

#if ENABLE_VERT_GRADIENT
    col *= VerticalGradient(tex, VERT_GRAD_AMOUNT);
#endif

#if ENABLE_CHROMA_ABERR
    col = ChromaticAberration(col, tex, CHROMA_ABERR_AMOUNT);
#endif

#if ENABLE_LENS_DIRT
    col = LensDirt(col, tex, LENS_DIRT_AMOUNT);
#endif

#if ENABLE_TPDF_DITHER
    float n1 = Hash12(tex * float2(width, height));
    float n2 = Hash12(tex * float2(width, height) + 0.5);
    col += (n1 - n2) * (0.5 / 255.0);
#endif

    return saturate(col);
}

float3 BuildTopFillSM3(float2 tex, float yBorder)
{
    bool topSide = (tex.y < yBorder);
    float edgeY = topSide ? yBorder : (1.0 - yBorder);
    float d = topSide ? (yBorder - tex.y) : (tex.y - (1.0 - yBorder));
    float n = saturate(d / max(yBorder, 1e-4));
    float dir = topSide ? 1.0 : -1.0;

    float xSafe = clamp(tex.x, 0.08, 0.92);
    float xAnchor = lerp(xSafe, 0.5, 0.28 + 0.22 * n);
    float yWarp = (Hash12(float2(xSafe * width * 0.37 + n * 17.0, edgeY * 991.0)) - 0.5) * (0.45 * invH);

    float2 uvNear = float2(
        saturate(lerp(xSafe, xAnchor, 0.36)),
        saturate(edgeY + dir * (0.016 + 0.052 * n) + yWarp)
    );
    float2 uvMid = float2(
        saturate(lerp(xSafe, xAnchor, 0.70)),
        saturate(edgeY + dir * (0.070 + 0.128 * n) + yWarp)
    );
    float2 uvFar = float2(
        saturate(lerp(xSafe, 0.5, 0.82)),
        saturate(edgeY + dir * (0.138 + 0.214 * n) + yWarp)
    );

    float3 cNear = BlurAniso13(uvNear, 8.6 + 14.5 * n, 4.8 + 7.6 * n);
    float3 cMid = BlurAniso13(uvMid, 12.8 + 20.8 * n, 6.8 + 10.8 * n);
    float3 cFar = BlurAniso9(uvFar, 17.0 + 25.0 * n, 10.6 + 15.8 * n);
    float3 col = cNear * 0.45 + cMid * 0.34 + cFar * 0.21;
    float3 sweep = BlurAniso9(float2(xAnchor, uvMid.y), 16.0 + 24.0 * n, 4.0 + 6.4 * n);
    col = lerp(col, sweep, 0.05 + 0.07 * n);

    float xMirror = 1.0 - xSafe;
    float2 muv = float2(
        saturate(lerp(xMirror, xAnchor, 0.30)),
        saturate(edgeY + dir * (0.058 + 0.174 * n) + yWarp * 0.60)
    );
    float3 mirrorCol = BlurAniso9(muv, 9.4 + 15.5 * n, 4.8 + 8.0 * n);
    mirrorCol = SaturationLimit(mirrorCol, 0.78);
    mirrorCol = lerp(Luma(mirrorCol).xxx, mirrorCol, 1.06);

    // Multi-depth edge sampling: weight deeper samples more to avoid compression ringing.
    float2 edgeUV = float2(xSafe, saturate(edgeY + dir * (2.0 * invH)));
    float2 edgeUV2 = float2(xSafe, saturate(edgeY + dir * (4.0 * invH)));
    float2 edgeUV3 = float2(xSafe, saturate(edgeY + dir * (8.0 * invH)));
    float3 eDepth1 = BlurAniso9(edgeUV,  6.8, 2.2);
    float3 eDepth2 = BlurAniso9(edgeUV2, 7.5, 3.0);
    float3 eDepth3 = BlurAniso9(edgeUV3, 8.5, 3.5);
    float3 edge0 = eDepth1 * 0.25 + eDepth2 * 0.45 + eDepth3 * 0.30;
    float xStep = (4.0 + 6.0 * n) * invW;
    float3 edgeL = SampleRGB(edgeUV2 - float2(xStep, 0.0));
    float3 edgeR = SampleRGB(edgeUV2 + float2(xStep, 0.0));
    float3 edgeIn = BlurAniso9(float2(xAnchor, saturate(edgeY + dir * (8.0 * invH))), 8.3, 2.8);
    float3 edgeSoft = CleanEdgeColor(edge0, edgeL, edgeR, edgeIn, mirrorCol);
    float edgeLum = Luma(edgeSoft);
    float darkScene = saturate((0.24 - edgeLum) / 0.24);
    float darkSuppress = saturate(1.0 - 1.35 * darkScene);

    float3 palette = EdgePaletteTop(edgeY, dir, xAnchor, n);
    palette = SaturationLimit(palette, 0.86);

    float streakRisk = saturate((ColorDelta(edgeL, edgeR) - 0.06) / 0.22);
    float paletteAmt = 0.03 + 0.08 * n + 0.06 * streakRisk;
    float mirrorAmt = (0.02 + 0.05 * MirrorMask(n)) * (1.0 - 0.65 * streakRisk);
    paletteAmt *= darkSuppress;
    mirrorAmt *= darkSuppress;

    col = lerp(col, palette, paletteAmt);
    col = lerp(col, mirrorCol, mirrorAmt);

    float3 spread = BlurAniso13(float2(xAnchor, uvMid.y), 15.0 + 22.0 * n, 12.0 + 17.0 * n);
    float spreadAmt = saturate(0.22 + 0.16 * n + 0.24 * streakRisk);
    col = lerp(col, spread, spreadAmt);

    float shadowLock = saturate(0.24 + 0.62 * darkScene + 0.32 * streakRisk);
    float3 stableRef = lerp(edgeSoft, palette, 0.30);
    float stableAmt = shadowLock * (0.10 + 0.06 * n) * (0.35 + 0.65 * darkSuppress);
    col = lerp(col, stableRef, stableAmt);

    float edgeBoost = (1.0 - smoothstep(0.22, 0.86, n));
    col = lerp(col, MidContrast(col, 0.11), edgeBoost * 0.54);
    col = SatGuard(col, lerp(edgeSoft, palette, 0.48), n);
    float seam = smoothstep(0.002, 0.065, n);
    float rim = (1.0 - smoothstep(0.0, 0.032, n));
    // Soft-light blend at seam: organic film-like transition instead of hard lerp
    col = lerp(edgeSoft, BlendSoftLight(edgeSoft, col), seam);
    float rimAmt = rim * (1.0 - 0.90 * darkScene);
    col += edgeSoft * (0.0025 * rimAmt) + edgeLum.xxx * (0.0009 * rimAmt);

    float glowAmt = 0.050 * (1.0 - n) * (0.65 + 0.35 * saturate(edgeLum * 1.2));
    col = 1.0 - (1.0 - col) * (1.0 - edgeSoft * glowAmt);

    col = GradeAmbientSM3(col, n, edgeLum);
    col *= lerp(float3(0.99, 1.00, 1.02), float3(1.02, 1.00, 0.99), tex.y);
#if ENABLE_WARM_HALATION
    col = WarmHalation(col, edgeSoft, (HALATION_AMOUNT_BASE + HALATION_AMOUNT_FAR * (1.0 - n)) * (1.0 - HALATION_DARK_SUPPRESS * darkScene));
#endif
    col = ArtifactGuardSM3(col, edgeLum, darkScene, streakRisk);
    float darkSafe = saturate((darkScene - 0.16) / 0.44);
    float3 safeBlur = BlurAniso13(float2(xAnchor, uvMid.y), 8.0 + 10.0 * n, 8.0 + 10.0 * n);
    safeBlur = GradeAmbientSM3(safeBlur, n, edgeLum);
    safeBlur = ArtifactGuardSM3(safeBlur, edgeLum, darkScene, streakRisk);
    col = lerp(col, safeBlur, darkSafe * (0.80 + 0.20 * streakRisk));
    float brightSafe = saturate((edgeLum - 0.26) / 0.40) * (0.10 + 0.18 * streakRisk); // было 0.18+0.24 — тянуло к нейтральному safeBlur, убивало голубой
    col = lerp(col, safeBlur, brightSafe);
    col = SaturationLimit(col, lerp(0.54, 0.34, darkScene));
    col *= (1.0 - 0.07 * saturate(1.0 - n * 14.0));

    // Exponential fade — perceptually closer to real light falloff than pow()
    float fadeFloor = lerp(FADE_FLOOR_LIGHT, FADE_FLOOR_DARK, darkScene);
    float fadeN = smoothstep(0.0, 0.06, n); // soft entry at seam — no hard pop at n=0
    float fade = max(fadeFloor, exp(-n * FADE_DECAY_RATE)) * fadeN;
    col *= fade;

#if ENABLE_VIGNETTE
    col *= lerp(1.0, Vignette(tex), VIGNETTE_BLEND);
#endif

#if ENABLE_VERT_GRADIENT
    col *= VerticalGradient(tex, VERT_GRAD_AMOUNT);
#endif

#if ENABLE_CHROMA_ABERR
    col = ChromaticAberration(col, tex, CHROMA_ABERR_AMOUNT);
#endif

#if ENABLE_LENS_DIRT
    col = LensDirt(col, tex, LENS_DIRT_AMOUNT);
#endif

#if ENABLE_TPDF_DITHER
    float n1 = Hash12(tex * float2(width, height));
    float n2 = Hash12(tex * float2(width, height) + 0.5);
    col += (n1 - n2) * (0.5 / 255.0);
#endif

    return saturate(col);
}

float4 main(float2 tex : TEXCOORD0) : COLOR
{
    float4 src = tex2D(s0, tex);

    float sideDark = 0.5 * (IsDarkColumn(0.008) + IsDarkColumn(0.992));
    float topDark = 0.5 * (IsDarkRow(0.008) + IsDarkRow(0.992));
    // Guard: suppress fill on truly blank frames (e.g. hard cuts to black).
    // Use max of 5 center samples to avoid single-pixel noise triggering the guard.
    float cL = Luma(SampleRGB(float2(0.35, 0.50)));
    float cR = Luma(SampleRGB(float2(0.65, 0.50)));
    float cT = Luma(SampleRGB(float2(0.50, 0.35)));
    float cB = Luma(SampleRGB(float2(0.50, 0.65)));
    float cC = Luma(SampleRGB(float2(0.50, 0.50)));
    float centerLum = max(max(cL, cR), max(max(cT, cB), cC));
    bool hasSideBars = (centerLum > 0.02) && (sideDark > 0.54) && (sideDark >= topDark - 0.08);
    bool hasTopBars  = (centerLum > 0.02) && (topDark > 0.54) && (topDark > sideDark + 0.08);

    if (hasSideBars)
    {
        float xBorder = sideBorderBase;
        float p122 = 0.5 * (IsDarkColumn(0.122) + IsDarkColumn(0.878));
        float p128 = 0.5 * (IsDarkColumn(0.128) + IsDarkColumn(0.872));
        if (p128 > 0.66) xBorder = 0.128;
        else if (p122 < 0.33) xBorder = 0.122;

        float3 fill = BuildSideFillSM3(tex, xBorder);

        if (tex.x >= xBorder && tex.x <= 1.0 - xBorder)
        {
            float distIn = min(tex.x - xBorder, (1.0 - xBorder) - tex.x);
            float nearEdge = saturate(1.0 - distIn / hardBandSide);
            float srcLum = Luma(src.rgb);
            float darkGate = saturate((darkThreshold + 0.024 - srcLum) / 0.05);
            float outward = (tex.x < 0.5) ? -1.0 : 1.0;
            float2 probeUV = tex + float2(outward * (2.0 * invW), 0.0);
            float probeLum = Luma(SampleRGB(probeUV));
            float barGate = saturate((darkThreshold + 0.035 - probeLum) / 0.07);
            float blend = nearEdge * darkGate * barGate;
            return lerp(src, float4(fill, 1.0), blend);
        }

        return float4(fill, 1.0);
    }

    if (hasTopBars)
    {
        float yBorder = topBorderBase;
        float p122 = 0.5 * (IsDarkRow(0.122) + IsDarkRow(0.878));
        float p128 = 0.5 * (IsDarkRow(0.128) + IsDarkRow(0.872));
        if (p128 > 0.66) yBorder = 0.128;
        else if (p122 < 0.33) yBorder = 0.122;

        float3 fill = BuildTopFillSM3(tex, yBorder);

        if (tex.y >= yBorder && tex.y <= 1.0 - yBorder)
        {
            float distIn = min(tex.y - yBorder, (1.0 - yBorder) - tex.y);
            float nearEdge = saturate(1.0 - distIn / hardBandTB);
            float srcLum = Luma(src.rgb);
            float darkGate = saturate((darkThreshold + 0.024 - srcLum) / 0.05);
            float outward = (tex.y < 0.5) ? -1.0 : 1.0;
            float2 probeUV = tex + float2(0.0, outward * (2.0 * invH));
            float probeLum = Luma(SampleRGB(probeUV));
            float barGate = saturate((darkThreshold + 0.035 - probeLum) / 0.07);
            float blend = nearEdge * darkGate * barGate;
            return lerp(src, float4(fill, 1.0), blend);
        }

        return float4(fill, 1.0);
    }

    return src;
}

technique ProfessionalLighting_SM3
{
    pass P0
    {
        PixelShader = compile ps_3_0 main();
    }
}
