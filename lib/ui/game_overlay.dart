import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sand_bike_sim/game/sand_bike_game.dart';
import 'package:sand_bike_sim/antigravity/antigravity_core.dart';
import 'dart:async';

class GameOverlay extends StatefulWidget {
  final SandBikeGame game;

  const GameOverlay({super.key, required this.game});

  @override
  State<GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<GameOverlay> {
  String pitBossMessage = "System Online.";
  String displayedMessage = "";
  double _speed = 0.0;
  double _mmr = 1.0;
  bool _isGasPressed = false;
  
  StreamSubscription? _msgSub;
  StreamSubscription? _telSub;
  StreamSubscription? _mutSub;

  @override
  void initState() {
    super.initState();
    
    _msgSub = AntigravityCore.instance.pitBoss.messageStream.listen((msg) {
      if (mounted && pitBossMessage != msg) {
        setState(() {
          pitBossMessage = msg;
          displayedMessage = "";
        });
        _typewriterEffect(msg);
      }
    });

    _telSub = AntigravityCore.instance.telemetry.stream.listen((data) {
      if (mounted) {
        setState(() {
          _speed = data.velocity.length;
        });
      }
    });

    _mutSub = AntigravityCore.instance.trackMaster.mutationStream.listen((mutation) {
      if (mounted) {
        setState(() {
          _mmr = mutation.targetNoiseAmplitude;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _msgSub?.cancel();
    _telSub?.cancel();
    _mutSub?.cancel();
    super.dispose();
  }

  void _typewriterEffect(String text) async {
    for (int i = 0; i < text.length; i++) {
      if (!mounted || pitBossMessage != text) break;
      setState(() {
        displayedMessage = text.substring(0, i + 1);
      });
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _onGasDown() {
    if (widget.game.raceState.value != RaceState.racing) return;
    setState(() => _isGasPressed = true);
    widget.game.setThrottle(1.0);
  }

  void _onGasUp() {
    setState(() => _isGasPressed = false);
    widget.game.setThrottle(0.0);
  }
  
  String _formatTime(double time) {
    int minutes = time ~/ 60;
    int seconds = (time % 60).toInt();
    int ms = ((time * 100) % 100).toInt();
    return "$minutes:${seconds.toString().padLeft(2, '0')}:${ms.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RaceState>(
      valueListenable: widget.game.raceState,
      builder: (context, raceState, child) {
        return Stack(
          children: [
            // Top HUD
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("SPEED", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                      Text("${_speed.toStringAsFixed(1)} km/h", style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("DIFFICULTY MMR", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                      Text(_mmr.toStringAsFixed(2), style: const TextStyle(color: Colors.orangeAccent, fontSize: 24, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
                    ],
                  ),
                ],
              ),
            ),

            // Pit Boss dynamic UI
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Pit Boss: $displayedMessage",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Courier', fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Throttle Button (hidden if not racing)
            if (raceState == RaceState.racing)
              Positioned(
                bottom: 40,
                right: 40,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => _onGasDown(),
                  onTapUp: (_) => _onGasUp(),
                  onTapCancel: () => _onGasUp(),
                  child: Transform.scale(
                    scale: _isGasPressed ? 0.95 : 1.0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isGasPressed ? Colors.deepOrangeAccent : Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: _isGasPressed
                            ? [
                                BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2),
                                const BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))
                              ]
                            : const [
                                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(2, 4))
                              ]
                      ),
                      child: const Center(
                        child: Text("GAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                      ),
                    ),
                  ),
                ),
              ),
              
            // Pre-Race Overlay
            if (raceState == RaceState.preRace)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("SAND BIKE SIM", style: TextStyle(color: Colors.orange, fontSize: 32, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                        onPressed: () => widget.game.startGame(),
                        child: const Text("START GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                        onPressed: () => SystemNavigator.pop(),
                        child: const Text("QUIT GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              
            // Post-Race Overlay
            if (raceState == RaceState.finished)
              Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("RACE ENDED", style: TextStyle(color: Colors.cyanAccent, fontSize: 32, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black54,
                        ),
                        child: Column(
                          children: [
                            const Text("FINAL RESULTS", style: TextStyle(color: Colors.white, fontSize: 20, decoration: TextDecoration.none, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ...widget.game.raceResults.asMap().entries.map((entry) {
                              int index = entry.key;
                              var res = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  "${index + 1}. ${res['name']} - ${_formatTime(res['time'])}",
                                  style: TextStyle(
                                    color: res['name'] == 'Player' ? Colors.cyanAccent : Colors.white,
                                    fontSize: 18,
                                    decoration: TextDecoration.none,
                                    fontFamily: 'Courier'
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                            onPressed: () => widget.game.startGame(),
                            child: const Text("PLAY AGAIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                            onPressed: () => SystemNavigator.pop(),
                            child: const Text("QUIT GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
          ],
        );
      }
    );
  }
}
