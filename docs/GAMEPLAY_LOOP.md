# Gameplay loop

This document describes how the finished game is intended to function. It defines
player-facing rules, not technical implementation.

## Player fantasy

Players build a collection of unique dragons, care for them on their islands, train
them for competitions, hatch new dragons, and discover deterministic hybrid dragons
through fusion.

## Core loop

1. **Care for dragons.** Feed and groom dragons on their islands to keep them happy.
2. **Train dragons.** Choose from different training categories. Happy, well-cared-for
   dragons receive better training XP.
3. **Compete.** Enter trained dragons in the matching competition category.
4. **Earn gold.** Winning competitions awards gold.
5. **Buy eggs.** Spend gold on eggs.
6. **Hatch new dragons.** Eggs always contain a dragon the player does not own.
7. **Fuse dragons.** Spend Fusion Stars to combine two eligible dragons into a new,
   deterministic hybrid without losing either parent.
8. **Expand and repeat.** New dragons can be cared for, trained, entered in competitions,
   and used in future fusions.

```text
care → train → compete → gold → egg → hatch → expand collection
  └──────────────── Fusion Stars + eligible dragons → hybrid ─────┘
```

## Dragon collection

- A player can own only one of each unique dragon.
- Egg rewards exclude every dragon already owned.
- Each dragon lives on an island where it can be fed and groomed.
- Care, happiness, training progress, and competition progress belong to that dragon.

## Care and happiness

- Feeding and grooming improve a dragon's happiness.
- Happiness gives bonuses, including improved XP from training.
- A dragon must be happy and groomed before it is eligible for fusion.

Care supports progression: spending time with dragons makes training and fusion more
effective.

## Training and competitions

- Training is divided into categories, such as Flight.
- Each category has its own training activity and matching competition.
- Dragons improve through training, then use that progress in competition.
- Winning competitions awards gold, which funds further egg purchases.

## Eggs

- Eggs are purchased with gold.
- Hatching an egg adds a new dragon to the collection.
- An egg always produces an unowned dragon, preventing duplicates.
- When an egg pool contains no unowned dragons, it cannot award another dragon until
  more eligible dragons are added to that pool.

## Fusion

- Fusion uses a separate currency called **Fusion Stars**.
- Both parent dragons must be happy and groomed.
- Fusion does not consume or replace either parent.
- Every valid dragon pairing has a deterministic result that can be shown before fusion.
- A fusion cannot create a duplicate of a dragon already owned.

For example, fusing an Ice dragon with a Fire dragon creates the defined Ice/Fire
hybrid for that pairing.

## Dragon types

- Dragon types are represented as a list.
- Base dragons normally have one type.
- Current fusion dragons can have up to two types.
- The design can later support three-type dragons without changing the core loop.

## Decisions still open

- Additional training and competition categories.
- Exact happiness tiers and XP bonuses.
- How Fusion Stars are earned and how much each fusion costs.
- Egg pools, dragon rarity, and progression pacing.
- When three-type fusion becomes available.
