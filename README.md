# 📜 Instant Hunting Log

A real-time experience tracking system for **Mu Online Season 6** that displays **EXP per minute**, **last EXP received**, **level-up progress**, and **estimated time to the next level**. This system provides both **server-side** and **client-side** scripts to enhance the gameplay experience.

---

## 🛠 Features

- 🔹 Displays **EXP per minute**, **last EXP received**, **level-ups**, and **estimated time for next level-ups**.
- 🔹 Uses **custom UI framework** to create a **professional-looking HUD**.
- 🔹 Automatically updates **every 60 seconds** to keep track of the player’s farming efficiency.
- 🔹 **Accurate calculations** for **EXP gain & time remaining** for level-ups.
- 🔹 Seamlessly integrates with the **Mu Online game client and server**.
- 🔹 Uses **Lua-based scripting** for both **server-side** and **client-side** functionalities.

---

## 🚩 Known-Issues
- 🔹The hunting log UI is not properly aligned when using different resolutions
- 🔹Master level exp is not being displayed in the log

## 📷 Images

![Hunting Log UI](https://i.ibb.co/gb63xGCY/Screen-03-02-01-53-0000.jpg)

![EXP Tracking](https://i.ibb.co/b5TVztyL/huntinglog.png)


## 🏗 How It Works

The **Instant Hunting Log** is implemented using **Lua scripts** that interact with the **Mu Online** server and client.

### 🖥 Server-Side (GameServer)

1. **Tracks EXP Gains**: The server tracks the player's experience **each time a monster dies**.
2. **Accumulates EXP Per Minute**: Every **60 seconds**, the script records **total EXP gained per minute**.
3. **Calculates Next Level Time**: Based on **EXP gain rate**, the script estimates the **time remaining** until the **next level**, **reset level (350)**, and **max level (400)**.
4. **Sends Data to Client**: The server sends **EXP per minute, last EXP gained, levels gained, and time until next level** through a **custom packet**.

### 🎮 Client-Side (Game Client)

1. **Receives EXP Data**: The game client listens for incoming **EXP data packets** from the server.
2. **Processes the Packet Data**: Extracts **EXP per minute**, **last EXP received**, **level-ups**, and **next level time**.
3. **Displays HUD**: The information is rendered **in a sleek, professional UI** using a **custom UI framework**.
4. **Auto-hide Feature**: The UI automatically hides when the **EXP per minute is zero**, ensuring a **clean interface**.

---

## 📡 Packet Data Structure

The server communicates with the client using **a custom packet format** (`HUNTING_LOG_PACKET`).

| **Byte Offset** | **Data Type** | **Description** |
|---------------|------------|----------------|
| 0  | `DWORD` | **EXP per minute** |
| 4  | `DWORD` | **Last EXP received** |
| 8  | `DWORD` | **Levels gained** |
| 12 | `DWORD` | **Time (seconds) to next level** |
| 16 | `DWORD` | **Time (seconds) to max level (400)** |
| 20 | `DWORD` | **Time (seconds) to reset level (350)** |

### 🔹 Example Packet Data

