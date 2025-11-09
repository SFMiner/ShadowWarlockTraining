# 🕸️ Shadow Warlock Training

**An Educational Tactical Puzzle Game Teaching Geometric Transformations**

[![Platform](https://img.shields.io/badge/platform-HTML5-orange.svg)](https://sfminer.github.io)
[![Engine](https://img.shields.io/badge/engine-Godot%204.5-blue.svg)](https://godotengine.org/)
[![Target](https://img.shields.io/badge/grade-6--8-green.svg)](https://www.corestandards.org/Math/)
[![License](https://img.shields.io/badge/license-Educational-purple.svg)]()

> Transform your understanding of geometry through strategic shadow magic.

## 🎮 What is Shadow Warlock Training?

Shadow Warlock Training is a browser-based educational game that teaches geometric transformations (translation, reflection, rotation, and dilation) through engaging turn-based tactical puzzles. Students play as a shadow warlock apprentice who must master transformation magic to navigate through "The Dark Reflection" and confront The Architect.

**Core Innovation:** The game features a turn-based system where enemies telegraph their actions before you move. Victory comes from using transformations strategically to reposition yourself, objects, and enemies so attacks miss, hit each other, or become neutralized.

## 🎯 Educational Goals

### Learning Objectives
- ✅ Master geometric transformations: **Translation**, **Reflection**, **Rotation**, and **Dilation**
- ✅ Understand transformation properties (preserves distance, changes orientation, etc.)
- ✅ Develop spatial reasoning and visualization skills
- ✅ Apply mathematical concepts in strategic problem-solving

### Standards Alignment
- **Common Core Math:** 8.G.A.1, 8.G.A.2, 8.G.A.3
- **NCTM Geometry Standards** for middle grades

## 🌟 Key Features

### The Four Shadow Arts (Transformations)

1. **Shadow Slide** (Translation)
	- Glide through shadows to move in straight lines
	- Preserves orientation and size
	- Range increases with player level (2-10 tiles)

2. **Mirrorwalk** (Reflection)
	- Create mirror lines to reflect across
	- Flips orientation while preserving distance
	- Essential for dodging and repositioning

3. **Turn / Shadow Pivot** (Rotation)
	- Rotate around a chosen pivot point
	- Turn: Rotate self around external point
	- Shadow Pivot: Rotate target around self
	- Angles: 90°, 180°, 270° (45° increments in advanced mode)

4. **Shadowshift** (Dilation)
	- Change the size of self, objects, or enemies
	- Center point remains fixed during scaling
	- Progressive unlocks: Self → Objects → Enemies

### Game Structure

**12 Levels Total:**
- **Levels 1-4:** Training levels teaching each transformation
- **Levels 5-11:** Tactical puzzles combining multiple transformations
- **Level 12:** Boss fight against The Architect

### Progression System

- **Level-Based Power Scaling:** Transformation ranges increase as you level up
- **Ability Unlocks:** New capabilities unlock at specific levels
- **Multi-Target Mastery:** Progress from affecting one target to multiple targets efficiently
- **Three Difficulty Modes:** Easy (training), Normal (balanced), Hard (challenge)

### Enemy Types

1. **Pale Hounds** - Aggressive melee attackers with simple patrol patterns
2. **Mirror Wraiths** - Teleporting enemies that create strategic positioning puzzles
3. **Hollow Sentinels** - Stationary ranged attackers requiring precise dodging
4. **The Architect** (Boss) - Multi-phase final challenge testing all transformation skills

## 🎓 For Educators

### Classroom Integration

**Time Requirements:**
- Single session: 20-30 minutes
- Full playthrough: 45-60 minutes
- Perfect for single class period or multiple sessions

**Pedagogical Approach:**
- **Kinesthetic Learning:** Interactive drag-and-drop transformation mechanics
- **Immediate Feedback:** Visual confirmation of correct/incorrect transformations
- **Mastery-Based:** Cannot advance without demonstrating understanding
- **Multiple Solutions:** Encourages creative problem-solving

### Differentiation

**Easy Mode ("Shadow Training"):**
- No enemies in main levels
- Unlimited time for decisions
- Sequential enemy telegraphs (when present)
- Focus purely on transformation understanding

**Normal Mode ("Warlock's Path"):**
- Balanced challenge for typical students
- Unlimited planning time
- Sequential enemy animations
- Standard progression

**Hard Mode ("Shadowmaster Challenge"):**
- Advanced challenge for mastery
- 20-second time limit per turn
- Simultaneous enemy animations
- Additional enemies and hazards

### Assessment Opportunities

**Formative Assessment:**
- Observe student approaches to puzzles
- Identify misconceptions through failed attempts
- Track which transformations students prefer/avoid

**Summative Assessment:**
- Level completion demonstrates competency
- Hard mode success shows deep understanding
- Post-game discussion prompts included in documentation

## 🚀 Getting Started

### Play Online

Visit **[sfminer.github.io/shadow-warlock-training](https://sfminer.github.io/shadow-warlock-training)** (when deployed)

The game runs entirely in your browser - no downloads required!

### System Requirements

- **Browser:** Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Connection:** Internet required for first load (then playable offline via PWA)
- **Display:** 1280x720 minimum resolution
- **Input:** Mouse/trackpad or touch screen

### Progressive Web App (PWA)

After first visit, the game can be installed as a Progressive Web App:
1. Click the install prompt in your browser
2. Game works offline after installation
3. Faster load times on subsequent visits
4. Perfect for classroom Chromebooks with unreliable WiFi

## 🛠️ Technical Details

### Built With

- **Engine:** Godot 4.5
- **Language:** GDScript
- **Platform:** HTML5/WebAssembly
- **Save System:** Browser localStorage
- **Art Style:** Pixel art (32x32 tile grid)
- **Audio:** Royalty-free from Pixabay

### Project Structure

```
shadow-warlock-training/
├── scripts/
│   ├── autoload/
│   │   ├── game_constants.gd    # Balance parameters & formulas
│   │   └── game_manager.gd      # Progression & save system
│   ├── player/
│   │   └── player_avatar.gd     # Four transformation abilities
│   └── enemies/
│       ├── enemy_base.gd        # Base enemy class
│       ├── hound.gd             # Pale Hound implementation
│       ├── mirror_wraith.gd     # Mirror Wraith implementation
│       └── hollow_sentinel.gd   # Hollow Sentinel implementation
├── scenes/
│   ├── levels/                  # 12 level scenes
│   ├── ui/                      # Menus and HUD
│   └── entities/                # Player and enemy scenes
├── assets/
│   ├── sprites/                 # Pixel art assets
│   ├── audio/                   # Music and SFX
│   └── fonts/                   # UI fonts
└── docs/
	├── GDD_Complete.md          # Full game design document
	├── Implementation_Plan.md   # Development roadmap
	└── Task_List.md             # Haiku-delegated tasks
```

### Performance

- **Target:** 60 FPS on classroom Chromebooks
- **Build Size:** <40MB uncompressed (<20MB gzipped)
- **Load Time:** ≤8 seconds cold load on school networks
- **Save System:** Auto-saves progress to browser localStorage

## 📚 Documentation

### Complete Documentation

- **[Game Design Document](./docs/Shadow_Warlock_Training_GDD_Complete_4_3.md)** - Complete design specification
- **[Implementation Plan](./docs/Shadow_Warlock_Training_-_Implementation_Plan_for_AI-Assisted_Development.md)** - Development roadmap and architecture
- **[Task List](./docs/Shadow_Warlock_Training_Haiku_Task_List.md)** - Detailed implementation tasks

### Core Game Files

- **[game_constants.gd](./game_constants.gd)** - Tunable balance parameters
- **[game_manager.gd](./game_manager.gd)** - Progression and save system
- **[player_avatar.gd](./player_avatar.gd)** - Transformation implementations
- **[enemy_base.gd](./enemy_base.gd)** - Enemy behavior framework

## 🎮 Gameplay Overview

### Turn Structure

Each turn consists of three phases:

1. **Enemy Telegraph Phase**
	- Enemies show their intended actions
	- Visual indicators reveal attack paths
	- Plan your counter-strategy

2. **Player Action Phase**
	- Choose and execute transformations
	- Drag-and-drop interface for easy control
	- Real-time preview of transformation results

3. **Resolution Phase**
	- Enemies execute their actions
	- Evaluate success/failure
	- Plan next move

### Victory Conditions

- **Training Levels:** Reach the goal tile
- **Tactical Levels:** Survive enemy waves and reach goal
- **Boss Level:** Defeat The Architect across multiple phases

### Transformation Combos

As you level up, unlock powerful multi-step transformations:
- **Level 4:** 2-step combos
- **Level 7:** 3-step combos
- **Level 8:** 4-step combos

Combine transformations creatively for optimal solutions!

## 🏆 New Game+ / Shadow Mastery Mode

After completing the main game, unlock Shadow Mastery Mode featuring:

- **Time Trials:** Race against the clock
- **Minimal Moves:** Optimize your solutions
- **No-Reset Runs:** Perfect execution challenges
- **Level Variants:** Mirrored layouts and new configurations
- **Boss Rush:** Ultimate test of mastery
- **Cosmetic Unlocks:** Customize your warlock's appearance

## 🤝 Contributing

This is an educational project developed for middle school mathematics education. Contributions, suggestions, and feedback are welcome!

### Development Setup

1. Install [Godot 4.5](https://godotengine.org/download)
2. Clone this repository
3. Open project in Godot Editor
4. Press F5 to run

### Code Style

- **Language:** GDScript
- **Indentation:** Tabs (not spaces)
- **Naming:** snake_case for variables and functions
- **Comments:** Document complex transformations and formulas

## 📖 Educational Philosophy

> "Shadow Warlock Training demonstrates that educational games can achieve both pedagogical rigor and genuine entertainment value when mechanics are carefully designed to embody mathematical concepts rather than merely decorating drill-and-practice activities with game elements."

The game was designed following these principles:

1. **Mechanics Embody Concepts:** Transformations aren't just answers - they're strategic tools
2. **Kinesthetic Learning:** Interactive manipulation mirrors hands-on classroom activities
3. **Immediate Feedback:** Visual confirmation reinforces correct understanding
4. **Multiple Solution Paths:** Encourage creative problem-solving
5. **Intrinsic Motivation:** Progression through mastery, not just completion

## 📝 Post-Game Discussion Prompts

Use these questions to extend learning beyond gameplay:

- Where have you seen reflections in real life?
- How do video games use transformations?
- What careers use geometric transformations?
- How would you design a new level for this game?
- Which transformation was most useful? Why?
- What real-world objects change size while keeping their center fixed?

## 📊 Success Metrics

### Educational Targets
- **Knowledge Retention:** 80% correct on post-game quiz
- **Transfer:** 75% success on paper-based problems
- **Engagement:** 15-20 minutes sustained play
- **Completion:** 70% finish all 12 levels

### Technical Targets
- **Performance:** Stable 60 FPS
- **Load Time:** <3 seconds after PWA install
- **Compatibility:** Works on Chrome, Firefox, Safari, Edge
- **Reliability:** 99.9% save/load success rate

## 🙏 Acknowledgments

- **Educational Framework:** Aligned with Common Core State Standards
- **Audio Assets:** Royalty-free music from [Pixabay](https://pixabay.com/)
- **Game Engine:** [Godot Engine](https://godotengine.org/)
- **Inspiration:** Hands-on transformation activities from middle school mathematics curriculum

## 📄 License

This project is intended for educational use. Please contact for commercial licensing inquiries.

---

**Version:** 4.3 (Master Reference)  
**Last Updated:** November 9, 2025  
**Status:** Ready for Implementation  
**Developer:** Sean (SFMiner)  
**Platform:** [sfminer.github.io](https://sfminer.github.io)

---

### 🎯 Quick Links

- 🎮 [Play Online](https://sfminer.github.io/shadow-warlock-training) (when deployed)
- 📖 [Full Documentation](./docs/)
- 🐛 [Report Issues](https://github.com/sfminer/shadow-warlock-training/issues)
- 💬 [Educator Resources](./docs/educator-guide.md) (coming soon)

---

*"In the Dark Reflection, shadows bend to will, not force. Master the transformations, and shadow need not consume."*
