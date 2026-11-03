const STUDY = (() => {
const palettes = {
    dusk: ['#232326', '#e5dde9', '#b2a7ed', '#7c8be8', '#d1b184'],
    signature: ['#27272c', '#f0e2ed', '#cdadc6', '#9099e4', '#4f6fa9'],
    code: ['#232326', '#85b695', '#88b2b5', '#ecc06d', '#b380b0'],
};
function random(seed) {
    let value = seed >>> 0;
    return () => {
        value = (value * 1664525 + 1013904223) >>> 0;
        return value / 4294967296;
    };
}
function noise(x, y, seed) {
    const value = Math.sin(x * 12.9898 + y * 78.233 + seed * 37.719) * 43758.5453;
    return value - Math.floor(value);
}
function drawStipple(ctx, width, height, colors, density, variation, seed) {
    const rand = random(seed);
    const step = Math.max(10, 52 - density * 0.38);
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    for (let y = -step; y < height + step; y += step) {
        for (let x = -step; x < width + step; x += step) {
            const field = noise(x / width * 4, y / height * 4, seed);
            const jitter = step * variation * 0.35;
            const px = x + step / 2 + (rand() - 0.5) * jitter;
            const py = y + step / 2 + (rand() - 0.5) * jitter;
            const radius = step * (0.08 + field * 0.34) * (0.6 + rand() * variation * 0.9);
            ctx.fillStyle = colors[1 + Math.floor(rand() * (colors.length - 1))];
            ctx.globalAlpha = 0.35 + rand() * 0.65;
            ctx.beginPath();
            ctx.arc(px, py, radius, 0, Math.PI * 2);
            ctx.fill();
        }
    }
    ctx.globalAlpha = 1;
}
function drawPixel(ctx, width, height, colors, density, variation, seed) {
    const rand = random(seed);
    const step = Math.max(8, Math.round(42 - density * 0.28));
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    for (let y = 0; y < height; y += step) {
        for (let x = 0; x < width; x += step) {
            const field = noise(x / width * 5, y / height * 5, seed);
            if (rand() > 0.42 + field * 0.45)
                continue;
            const color = colors[1 + Math.floor(rand() * (colors.length - 1))];
            ctx.fillStyle = color;
            ctx.globalAlpha = 0.45 + rand() * 0.55;
            const block = rand() < variation * 0.5 ? step * (1 + Math.floor(rand() * 3)) : step;
            ctx.fillRect(x, y, block, block);
            if (rand() < 0.18) {
                ctx.fillStyle = colors[0];
                ctx.fillRect(x + step * 0.35, y + step * 0.35, step * 0.3, step * 0.3);
            }
        }
    }
    ctx.globalAlpha = 1;
}
function drawTile(ctx, x, y, size, color, type, rotation) {
    ctx.save();
    ctx.translate(x + size / 2, y + size / 2);
    ctx.rotate(rotation);
    ctx.fillStyle = color;
    if (type === 0) {
        ctx.fillRect(-size * 0.42, -size * 0.42, size * 0.84, size * 0.84);
    }
    else if (type === 1) {
        ctx.beginPath();
        ctx.arc(0, 0, size * 0.43, 0, Math.PI * 2);
        ctx.fill();
    }
    else if (type === 2) {
        ctx.beginPath();
        ctx.moveTo(-size * 0.5, size * 0.5);
        ctx.lineTo(size * 0.5, size * 0.5);
        ctx.lineTo(size * 0.5, -size * 0.5);
        ctx.closePath();
        ctx.fill();
    }
    else {
        ctx.fillRect(-size * 0.44, -size * 0.1, size * 0.88, size * 0.2);
        ctx.fillRect(-size * 0.1, -size * 0.44, size * 0.2, size * 0.88);
    }
    ctx.restore();
}
function drawTiles(ctx, width, height, colors, density, variation, seed) {
    const rand = random(seed);
    const size = Math.max(26, 100 - density * 0.6);
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    for (let y = 0; y < height; y += size) {
        for (let x = 0; x < width; x += size) {
            if (rand() > 0.76 + variation * 0.18)
                continue;
            const color = colors[1 + Math.floor(rand() * (colors.length - 1))];
            const type = Math.floor(rand() * 4);
            const rotation = Math.floor(rand() * 4) * Math.PI / 2 + (rand() - 0.5) * variation;
            drawTile(ctx, x, y, size, color, type, rotation);
        }
    }
}
function drawFold(ctx, width, height, colors, density, variation, seed) {
    const patch = document.createElement('canvas');
    patch.width = Math.ceil(width / 2);
    patch.height = Math.ceil(height / 2);
    const pctx = patch.getContext('2d');
    if (!pctx)
        return;
    const rand = random(seed);
    const cell = Math.max(12, Math.round(48 - density * 0.3));
    pctx.fillStyle = colors[0];
    pctx.fillRect(0, 0, patch.width, patch.height);
    for (let y = 0; y < patch.height; y += cell) {
        for (let x = 0; x < patch.width; x += cell) {
            if (rand() > 0.52 + variation * 0.25)
                continue;
            pctx.fillStyle = colors[1 + Math.floor(rand() * (colors.length - 1))];
            const w = cell * (0.35 + rand() * 0.75);
            const h = cell * (0.35 + rand() * 0.75);
            pctx.save();
            pctx.translate(x + cell / 2, y + cell / 2);
            pctx.rotate((rand() - 0.5) * variation);
            pctx.fillRect(-w / 2, -h / 2, w, h);
            pctx.restore();
        }
    }
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    const transforms = [[1, 1], [-1, 1], [1, -1], [-1, -1]];
    transforms.forEach(([sx, sy]) => {
        ctx.save();
        ctx.translate(width / 2, height / 2);
        ctx.scale(sx, sy);
        ctx.drawImage(patch, 0, 0);
        ctx.restore();
    });
}
function drawTerrain(ctx, width, height, colors, density, variation, seed) {
    const phase = seed * 0.73;
    const scale = 2.4 + density * 0.035;
    const warp = 0.4 + variation * 2.8;
    const bands = Math.max(5, Math.round(7 + density * 0.17));
    const resolution = 3;
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    for (let y = 0; y < height; y += resolution) {
        for (let x = 0; x < width; x += resolution) {
            const nx = x / width;
            const ny = y / height;
            const wx = nx + Math.sin(ny * 7 + phase) * warp * 0.08;
            const wy = ny + Math.cos(nx * 6 - phase) * warp * 0.08;
            const field = (Math.sin(wx * scale * 3 + phase) * 0.42 +
                Math.cos(wy * scale * 3.4 - phase) * 0.32 +
                Math.sin((wx + wy) * scale * 2.1) * 0.18 +
                Math.cos(Math.hypot(wx - 0.45, wy - 0.55) * scale * 6) * 0.22);
            const level = Math.max(0, Math.min(bands - 1, Math.floor((field + 1.15) / 2.3 * bands)));
            const colorIndex = 1 + (level % (colors.length - 1));
            ctx.fillStyle = colors[colorIndex];
            ctx.globalAlpha = 0.58 + (level % 3) * 0.18;
            ctx.fillRect(x, y, resolution + 0.5, resolution + 0.5);
        }
    }
    ctx.globalAlpha = 1;
}
function drawWarp(ctx, width, height, colors, density, variation, seed) {
    const rand = random(seed);
    const phase = rand() * Math.PI * 2;
    const stripe = Math.max(8, 38 - density * 0.28);
    const amplitude = 20 + variation * height * 0.22;
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    for (let i = -4; i < width / stripe + 5; i++) {
        ctx.fillStyle = colors[1 + (Math.abs(i) % (colors.length - 1))];
        ctx.beginPath();
        for (let y = -20; y <= height + 20; y += 5) {
            const t = y / height;
            const envelope = Math.sin(t * Math.PI);
            const x = i * stripe + Math.sin(t * Math.PI * (1.5 + variation * 2) + phase) * amplitude * envelope + Math.sin(t * 15 + phase) * variation * 12;
            if (y === -20)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        for (let y = height + 20; y >= -20; y -= 5) {
            const t = y / height;
            const envelope = Math.sin(t * Math.PI);
            const x = i * stripe + stripe * 0.52 + Math.sin(t * Math.PI * (1.5 + variation * 2) + phase) * amplitude * envelope + Math.sin(t * 15 + phase) * variation * 12;
            ctx.lineTo(x, y);
        }
        ctx.closePath();
        ctx.fill();
    }
}
function drawFilament(ctx, width, height, colors, density, variation, seed) {
    const rand = random(seed);
    const strands = Math.round(35 + density * 2.1);
    const steps = Math.round(35 + density * 0.65);
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    for (let i = 0; i < strands; i++) {
        const bundle = Math.floor(rand() * 7);
        let x = (bundle + 0.5) / 7 * width + (rand() - 0.5) * width * 0.12;
        let y = rand() * height;
        let angle = rand() * Math.PI * 2;
        const curl = (rand() - 0.5) * (0.08 + variation * 0.42);
        const length = 2 + rand() * (4 + variation * 8);
        ctx.strokeStyle = colors[1 + Math.floor(rand() * (colors.length - 1))];
        ctx.globalAlpha = 0.24 + rand() * 0.6;
        ctx.lineWidth = 0.45 + rand() * (0.8 + variation * 2);
        ctx.beginPath();
        ctx.moveTo(x, y);
        for (let j = 0; j < steps; j++) {
            angle += curl + Math.sin(j * 0.13 + i) * variation * 0.08;
            x += Math.cos(angle) * length;
            y += Math.sin(angle) * length;
            ctx.lineTo(x, y);
        }
        ctx.stroke();
    }
    ctx.globalAlpha = 1;
}
function drawWeave(ctx, width, height, colors, density, variation, seed) {
    const rand = random(seed);
    const bands = Math.round(5 + density * 0.12);
    const spacing = height / bands;
    const amplitude = spacing * (0.3 + variation * 1.2);
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    for (let i = -2; i < bands + 2; i++) {
        const phase = rand() * Math.PI * 2;
        const thickness = spacing * (0.28 + rand() * 0.32);
        const baseY = i * spacing;
        const color = colors[1 + (Math.abs(i) % (colors.length - 1))];
        ctx.fillStyle = color;
        ctx.globalAlpha = 0.88;
        ctx.beginPath();
        for (let x = -20; x <= width + 20; x += 6) {
            const y = baseY + Math.sin(x / width * Math.PI * 4 + phase) * amplitude;
            if (x === -20)
                ctx.moveTo(x, y - thickness / 2);
            else
                ctx.lineTo(x, y - thickness / 2);
        }
        for (let x = width + 20; x >= -20; x -= 6) {
            const y = baseY + Math.sin(x / width * Math.PI * 4 + phase) * amplitude;
            ctx.lineTo(x, y + thickness / 2);
        }
        ctx.closePath();
        ctx.fill();
        ctx.strokeStyle = colors[0];
        ctx.globalAlpha = 0.24;
        ctx.lineWidth = 1;
        for (let thread = 1; thread < 5; thread++) {
            ctx.beginPath();
            for (let x = -20; x <= width + 20; x += 6) {
                const y = baseY + Math.sin(x / width * Math.PI * 4 + phase) * amplitude - thickness / 2 + thickness * thread / 5;
                if (x === -20)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.stroke();
        }
    }
    ctx.globalAlpha = 1;
}
function drawMoire(ctx, width, height, colors, density, variation, seed) {
    const rand = random(seed);
    const ax = width * (0.22 + rand() * 0.18);
    const ay = height * (0.3 + rand() * 0.3);
    const bx = width * (0.62 + rand() * 0.2);
    const by = height * (0.25 + rand() * 0.45);
    const frequency = 0.045 + density * 0.0015;
    const resolution = 3;
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    for (let y = 0; y < height; y += resolution) {
        for (let x = 0; x < width; x += resolution) {
            const a = Math.hypot(x - ax, y - ay) * frequency;
            const b = Math.hypot(x - bx, y - by) * frequency * (0.88 + variation * 0.25);
            const interference = Math.cos(a) + Math.cos(b + seed * 0.2);
            const band = Math.floor((interference + 2) * 3.5);
            ctx.fillStyle = colors[1 + (Math.abs(band) % (colors.length - 1))];
            ctx.globalAlpha = Math.abs(interference) < 0.34 ? 1 : 0.16;
            ctx.fillRect(x, y, resolution + 0.5, resolution + 0.5);
        }
    }
    ctx.globalAlpha = 1;
}
function drawMarble(ctx, width, height, colors, density, variation, seed) {
    const phase = seed * 0.91;
    const bands = 5 + density * 0.18;
    const turbulence = 18 + variation * 95;
    const resolution = 3;
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    for (let y = 0; y < height; y += resolution) {
        for (let x = 0; x < width; x += resolution) {
            const nx = x / width;
            const ny = y / height;
            const broad = Math.sin(nx * Math.PI * 2 + phase) * turbulence;
            const detail = Math.sin(nx * 17 + ny * 4 + phase) * turbulence * variation * 0.24;
            const current = y + broad + detail + Math.sin(ny * 8 + phase) * variation * 18;
            const band = Math.floor(current / height * bands);
            ctx.fillStyle = colors[1 + (Math.abs(band) % (colors.length - 1))];
            ctx.globalAlpha = 0.82;
            ctx.fillRect(x, y, resolution + 0.5, resolution + 0.5);
        }
    }
    ctx.globalAlpha = 1;
}
function drawOrbit(ctx, width, height, colors, density, variation, seed) {
    const rand = random(seed);
    const traces = Math.round(3 + density * 0.07);
    const base = Math.min(width, height) * 0.25;
    const centers = [[width * 0.12, height * 0.22], [width * 0.88, height * 0.25], [width * 0.14, height * 0.82], [width * 0.86, height * 0.8]];
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    ctx.lineCap = 'round';
    centers.forEach(([cx, cy], cluster) => {
        for (let i = 0; i < traces; i++) {
            const ratio = 2 + Math.floor(rand() * 5);
            const offset = base * (0.2 + rand() * 0.55);
            const scale = 0.8 + rand() * 0.65;
            const rotation = rand() * Math.PI * 2;
            ctx.strokeStyle = colors[1 + ((i + cluster) % (colors.length - 1))];
            ctx.globalAlpha = 0.58 + rand() * 0.38;
            ctx.lineWidth = 1 + rand() * (1.2 + variation * 1.8);
            ctx.beginPath();
            for (let step = 0; step <= 800; step++) {
                const t = step / 800 * Math.PI * 2 * ratio;
                const x = (base - offset) * Math.cos(t) + offset * Math.cos((base - offset) / offset * t);
                const y = (base - offset) * Math.sin(t) - offset * Math.sin((base - offset) / offset * t);
                const px = cx + (x * Math.cos(rotation) - y * Math.sin(rotation)) * scale;
                const py = cy + (x * Math.sin(rotation) + y * Math.cos(rotation)) * scale * (0.75 + variation * 0.25);
                if (step === 0)
                    ctx.moveTo(px, py);
                else
                    ctx.lineTo(px, py);
            }
            ctx.stroke();
        }
    });
    ctx.globalAlpha = 1;
}
function drawDither(ctx, width, height, colors, density, variation, seed) {
    const bayer = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]];
    const pixel = Math.max(4, Math.round(13 - density * 0.08));
    const phase = seed * 0.61;
    ctx.fillStyle = colors[0];
    ctx.fillRect(0, 0, width, height);
    for (let y = 0; y < height; y += pixel) {
        for (let x = 0; x < width; x += pixel) {
            const nx = x / width;
            const ny = y / height;
            const left = Math.max(0, 1 - Math.hypot(nx - 0.12, ny - 0.35) * 1.8);
            const right = Math.max(0, 1 - Math.hypot(nx - 0.88, ny - 0.7) * 1.8);
            const wave = (Math.sin(nx * 15 + phase) + Math.cos(ny * 12 - phase)) * 0.13 * variation;
            const value = Math.max(left, right) + wave + 0.12;
            const threshold = bayer[Math.floor(y / pixel) % 4][Math.floor(x / pixel) % 4] / 16;
            const level = Math.floor((value - threshold * 0.7) * colors.length);
            if (level <= 0)
                continue;
            ctx.fillStyle = colors[Math.min(colors.length - 1, level)];
            ctx.globalAlpha = 0.9;
            ctx.fillRect(x, y, pixel, pixel);
        }
    }
    ctx.globalAlpha = 1;
}

return { palettes, draw: { stipple: drawStipple, pixel: drawPixel, tiles: drawTiles, fold: drawFold, terrain: drawTerrain, warp: drawWarp, filament: drawFilament, weave: drawWeave, moire: drawMoire, marble: drawMarble, orbit: drawOrbit, dither: drawDither } };
})();
