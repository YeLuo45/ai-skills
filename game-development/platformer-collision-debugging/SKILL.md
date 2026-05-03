---
name: platformer-collision-debugging
description: Debug jump/floor penetration and collision resolution bugs in HTML5 platformer games using Three.js or Canvas 2D. Covers velocity-direction-aware collision, gravity tuning, and head-vs-foot collision resolution.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [game-development, collision-detection, platformer, physics, debugging]
    related_skills: [systematic-debugging, game-studio]
---

# Platformer Collision Debugging

## Overview

Common jump/floor penetration bugs in 2.5D platformers where the character falls through platforms or dies unexpectedly. These bugs are caused by:

1. **Velocity-direction-agnostic collision resolution** — treating all collisions the same regardless of whether the player is rising or falling
2. **Gravity too high for platform thickness** — character tunnels through thin platforms in a single frame
3. **Head collision misinterpreted as floor collision** — during upward jump, character's head hits platform underside and is incorrectly resolved

## The Core Problem

In a typical platformer with AABB collision:

```javascript
// WRONG: resolves collision without considering velocity direction
if (overlaps) {
  // This breaks when player is jumping UP and head hits platform
  position.y = platform.bounds.max.y + halfHeight;
  velocity.y = 0; // stops ALL vertical motion, including upward!
}
```

When Mario jumps upward and his head hits a platform:
- Position gets pushed to below the platform
- Upward velocity is zeroed
- Mario gets stuck in the air (no longer grounded, no downward velocity yet)
- Gravity eventually kicks in but Mario is now floating above platform top

## The Fix Pattern

### 1. Velocity-Direction-Aware Resolution

```javascript
resolveCollisions(player, platforms) {
  const halfH = player.height / 2;
  const feetY = player.position.y - halfH;
  const headY = player.position.y + halfH;

  for (const platform of platforms) {
    const overlapBottom = headY - platform.bounds.min.y; // how far head is into platform
    const overlapTop = platform.bounds.max.y - feetY;    // how far feet are into platform top

    // Head collision (player rising into platform underside)
    if (overlapBottom > 0 && overlapTop > 0) {
      // Head collision only when player is moving UP
      if (player.velocity.y > 0) {
        player.position.y = platform.bounds.min.y - halfH;
        player.velocity.y = 0; // stop upward motion
        player.isGrounded = true;
        continue;
      }
    }

    // Foot collision (player falling onto platform top)
    if (overlapTop > 0 && overlapBottom > 0) {
      // Foot collision only when player is moving DOWN (or stationary)
      if (player.velocity.y <= 0) {
        player.position.y = platform.bounds.max.y + halfH;
        player.velocity.y = 0;
        player.isGrounded = true;
      }
    }
  }
}
```

**Key insight:** The condition `velocity.y <= 0` vs `velocity.y > 0` determines whether to resolve as foot vs head collision.

### 2. Gravity Tuning for Thin Platforms

If platform thickness is `T` and gravity is `G`:

```
terminal_velocity = sqrt(2 * G * max_fall_distance)
frame_velocity = terminal_velocity * delta_time

For 60fps: frame_velocity ≈ G / 30 (when falling from rest)
```

**Rule of thumb:** `frame_velocity < T * 0.3` to ensure at least 3 frames to detect collision.

Example: Platform height = 0.5 units, want frame_velocity < 0.15:
```
0.15 = G / 30
G = 4.5  (but this is too low for responsive jumps)

Alternative: increase platform thickness or use swept collision
```

**Practical tuning for Mario-like game:**
- Platform thickness: 0.5 units
- Ground detection tolerance: 0.15 units
- Gravity: 20 units/s² (not 25)
- Jump velocity: 12 units/s

This gives frame_velocity ≈ 20/30 = 0.67 at peak, but collision is checked every frame.

### 3. Ground State Tracking

```javascript
// Track grounded state explicitly
this.isGrounded = false;

update(deltaTime) {
  // Apply gravity
  if (!this.isGrounded) {
    this.velocity.y -= GRAVITY * deltaTime;
  }

  // Move
  this.position.addScaledVector(this.velocity, deltaTime);

  // Resolve collisions
  this.isGrounded = false; // reset each frame
  for (const platform of platforms) {
    this.resolveCollision(platform);
  }

  // Only allow jump when grounded
  if (jumpPressed && this.isGrounded) {
    this.velocity.y = JUMP_VELOCITY;
    this.isGrounded = false;
  }
}
```

## Debugging Checklist

When jump/floor penetration causes death or unexpected behavior:

- [ ] Is gravity too high for the platform thickness?
- [ ] Does collision resolution check `velocity.y` direction?
- [ ] Is `isGrounded` reset to `false` at start of each frame?
- [ ] Is Mario's initial position `y = halfHeight` (standing on platform, not inside)?
- [ ] Is the platform's `bounds.max.y` at the surface where Mario should stand?

## Common Bug Patterns

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| Mario dies immediately on flat ground | Initial y position is inside platform | Set y = halfHeight |
| Mario falls through floor | Gravity too high, tunnels in one frame | Lower gravity or increase floor thickness |
| Mario gets stuck in air after jump | Head collision resolves as floor collision | Add velocity.y check in resolution |
| Mario passes through thin platforms | Swept collision needed | Use continuous collision detection |
| Enemies fall through floor | Same gravity/collision issues | Apply same fixes to enemy class |

## Project Context

Used in: `~/.hermes/workspace-dev/proposals/super-mario-3d/`

Files:
- `js/player.js` — Mario collision logic
- `js/enemy.js` — Goomba/Koopa collision logic  
- `js/level.js` — Platform definitions

Mario physics parameters:
- Width: 0.8, Height: 1.0
- Move speed: 8 units/s
- Jump velocity: 12 units/s
- Gravity: 20 units/s²
- Initial position: y = 0.5 (halfHeight)

Ground platform: `{x: 0, y: 0, width: 100, height: 0.5, depth: 4}`
- bounds.min.y = -0.25, bounds.max.y = 0.25
