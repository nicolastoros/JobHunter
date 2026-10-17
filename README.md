# Crónicas del Cazador

RPG top-down de caza de monstruos en pixel art — Godot 4.7.

## Cómo abrir
Abre Godot 4.7.2 → **Importar** → selecciona `project.godot`. Pulsa F5 para jugar.

## Controles
| Acción | Teclado | Mando |
|---|---|---|
| Mover | WASD / Flechas | Stick izquierdo |
| Correr | Shift | B |
| Atacar | Espacio / J / Clic | X |
| Hablar | E / Enter | A |
| Pausa | Esc | Start |

## Estructura
```
assets/        sprites originales (mercado, espadachín lvl1-3, naturaleza) + licencias
resources/     tileset del mercado, SpriteFrames, tema de UI
scenes/
  ui/          menú principal, HUD (diálogos), pausa, opciones
  world/       market.tscn (mapa del mercado)
  characters/  player.tscn
  npc/         trader.tscn (comerciante), citizen.tscn (ciudadano que pasea)
scripts/       mismo orden que scenes/ + autoload/game.gd (transiciones, ajustes)
```

## Capas de colisión
1 `world` · 2 `player` · 3 `npc` · 4 `interactable` · 5 `enemy_hurtbox` (reservada para monstruos)

## Notas del mapa (`scenes/world/market.tscn`)
- `Ground`, `GroundDetails`, `Walls`: TileMapLayers. Solo `Walls` tiene colisión (definida por tile en `resources/tilesets/market_tileset.tres`).
- `Entities` usa Y-sort: puestos, NPCs y jugador se ordenan por profundidad. Cada puesto es un `StaticBody2D` cuyo origen está en su base, con la colisión solo en la huella del suelo.
- `NorthExit` / `SouthExit`: salidas por los portones. Asigna `target_scene` para conectar una zona de caza.
