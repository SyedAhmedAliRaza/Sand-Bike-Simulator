<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Game_Engine-Flame-orange?style=for-the-badge&logo=flame&logoColor=white" />
</div>

<h1 align="center">🏍️ Sand Bike Sim</h1>

<p align="center">
  <b>A highly dynamic, physics-based 2D racing game developed in Flutter using the Flame engine and Forge2D.</b>
</p>

<p align="center">
  <a href="YOUR_APK_URL_HERE">
    <img src="https://img.shields.io/badge/Download_APK-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Download APK" />
  </a>
</p>

---

## 🌟 Overview

**Sand Bike Sim** is not just another 2D racing game. It incorporates an intelligent backend system known as the **"Antigravity Core"** that processes telemetry data in real-time. This sophisticated core adapts the game's difficulty on the fly, controls rival AI behaviors, and manages the overall game state, creating a dynamic, highly engaging, and personalized player experience!

> [!NOTE]
> 🧠 **The Antigravity Core**: Learns from you, adapting the terrain and AI to keep you in the perfect state of flow.

## 🏗️ Overall Design & Architecture

The application is meticulously built on a **decoupled architecture**, ensuring high performance by separating the core game loop (frontend) from the intelligent agent systems (backend).

### 🎮 Frontend (Game Loop)
- **Tech Stack**: Built with Flutter and Flame.
- **Responsibilities**: Handles all rendering, physics simulation (powered by `Forge2D`), user inputs (device accelerometer and on-screen controls), and immersive haptic feedback.

### 🧠 Backend (Antigravity Core)
- **Architecture**: A collection of independent, highly specialized agents that subscribe to a centralized telemetry pipeline.
- **Responsibilities**: These agents analyze the player's performance in real-time and subtly mutate the game state (e.g., tweaking track difficulty, adjusting AI speed) accordingly.

> [!TIP]  
> **Why Decoupled?** This strict separation ensures that complex AI computations and data analysis do not block the main rendering thread. Communication between the frontend and the Antigravity Core happens asynchronously via **Dart Streams**, maintaining a buttery-smooth **60 FPS gameplay** experience!

---

## 🤖 Agents Developed

The `AntigravityCore` masterfully orchestrates several intelligent sub-agents, each with a specialized role:

- 📡 **`TelemetryPipeline`**: The central nervous system of the game. It collects high-frequency data from the game loop (throttle, tilt, air time, position, velocity, crash state) and broadcasts it at a stable **10 Hz tick rate** to all other listening agents.
- ⛰️ **`SmartTrackMaster`**: A procedural generation agent that controls the world. It analyzes the player's "Flow State" (e.g., high speed with no crashes vs. frequent crashes) and dynamically adjusts the terrain generation ahead. It mutates parameters like `targetNoiseAmplitude` and `surfaceFrictionCoefficient` using Perlin noise to make the track progressively harder or more forgiving.
- 👻 **`SmartRivalAi` (GhostRider)**: Controls your opponent on the track. It uses a smart rubber-banding heuristic based on the player's real-time telemetry. If you're far ahead, it increases its traction and target speed to catch up. If it's too far ahead, it dials back, ensuring a consistently competitive and nail-biting race!
- 🏁 **`Referee`**: The absolute authority. It validates the game state and monitors telemetry for specific edge conditions (like perfectly safe landings). Upon validation, it can inject events back into the game—such as rewarding you with a sudden speed boost.
- 🎯 **`PitBossAgent`**: Analyzes complex momentum vectors and triggers external events or UI messages based on significant gameplay achievements (for example, nailing a "Perfect Landing").

---

## 🛠️ APIs & Libraries Used

This project leverages several key Flutter packages to bring the simulation to life:

| Package | Description |
| :--- | :--- |
| 🛡️ **`flame` & `flame_forge2d`** | The core game engine and physics engine used for rendering the 2D world and handling rigid body dynamics (gravity, friction, complex collisions). |
| 🌊 **`fast_noise`** | Used heavily by the `SmartTrackMaster` for generating continuous, natural-looking 2D terrain (Perlin Noise) that can be dynamically mutated during gameplay. |
| 📱 **`sensors_plus`** | Accesses the device's hardware accelerometer. This allows players to intuitively control the bike's tilt in mid-air by physically tilting their device! |
| 📳 **`vibration` / `flutter/services`** | Utilizes `HapticFeedback` to provide immediate tactile responses during critical events like crashes or heavy landings, significantly enhancing player immersion. |

---

## 🔌 Integration Implementation

The integration between the high-speed game loop and the intelligent agent system relies entirely on reactive programming using **Dart `Stream`** and **`StreamController`**.

1. 📥 **Data Ingestion**: Inside the `SandBikeGame.update` loop, the current state data is packed tightly into a `TelemetryData` object and dispatched to the `TelemetryPipeline`.
2. 📡 **Broadcasting**: The pipeline decouples the heavy data ingestion from processing by using a `Timer`. It broadcasts the latest `TelemetryData` snapshot at a fixed, reliable interval (10 Hz).
3. ⚙️ **Agent Processing**: Sub-agents (like `SmartRivalAi` and `SmartTrackMaster`) constantly listen to this stream. Upon receiving a fresh tick, they analyze the data and update their internal state or broadcast mutation commands.
4. 🚀 **Game State Mutation**: The game loop listens to streams exposed by the agents (e.g., `trackMaster.mutationStream` or `referee.boostStream`) and immediately applies the changes (e.g., altering terrain parameters, applying physical impulses) in real-time.

---

<p align="center">
  <i>Developed with ❤️ for physics, AI, and smooth gameplay.</i>
</p>
