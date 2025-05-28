import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class BreathingExercisesPage extends StatefulWidget {
  const BreathingExercisesPage({super.key});

  @override
  State<BreathingExercisesPage> createState() => _BreathingExercisesPageState();
}

class _BreathingExercisesPageState extends State<BreathingExercisesPage>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  Timer? _timer;

  int _selectedExerciseIndex = 0;
  bool _isBreathing = false;
  int _currentPhase = 0; // 0: inhale, 1: hold, 2: exhale, 3: hold
  int _secondsRemaining = 0;
  int _totalCycles = 0;
  int _completedCycles = 0;

  final List<BreathingExercise> _exercises = [
    BreathingExercise(
      name: 'Box Breathing',
      description:
          'Equal counts for inhale, hold, exhale, and hold. Great for focus and calm.',
      inhaleSeconds: 4,
      hold1Seconds: 4,
      exhaleSeconds: 4,
      hold2Seconds: 4,
      cycles: 5,
      color: Colors.cyanAccent,
      icon: Icons.crop_square_rounded,
    ),
    BreathingExercise(
      name: '4-7-8 Breathing',
      description:
          'A natural tranquilizer for the nervous system. Helps with sleep.',
      inhaleSeconds: 4,
      hold1Seconds: 7,
      exhaleSeconds: 8,
      hold2Seconds: 0,
      cycles: 4,
      color: Colors.purpleAccent,
      icon: Icons.bedtime_rounded,
    ),
    BreathingExercise(
      name: 'Belly Breathing',
      description: 'Deep diaphragmatic breathing. Reduces stress and anxiety.',
      inhaleSeconds: 6,
      hold1Seconds: 2,
      exhaleSeconds: 6,
      hold2Seconds: 2,
      cycles: 6,
      color: Colors.greenAccent,
      icon: Icons.self_improvement_rounded,
    ),
    BreathingExercise(
      name: 'Quick Calm',
      description: 'Fast relief for acute stress. Short and effective.',
      inhaleSeconds: 3,
      hold1Seconds: 0,
      exhaleSeconds: 6,
      hold2Seconds: 0,
      cycles: 3,
      color: Colors.orangeAccent,
      icon: Icons.flash_on_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );
    _breathAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isBreathing = true;
      _currentPhase = 0;
      _completedCycles = 0;
      _totalCycles = _exercises[_selectedExerciseIndex].cycles;
    });
    _startPhase();
  }

  void _stopBreathing() {
    setState(() {
      _isBreathing = false;
      _currentPhase = 0;
      _completedCycles = 0;
    });
    _timer?.cancel();
    _breathController.stop();
    _breathController.reset();
  }

  void _startPhase() {
    if (!_isBreathing) return;

    final exercise = _exercises[_selectedExerciseIndex];
    int duration = 0;

    switch (_currentPhase) {
      case 0: // Inhale
        duration = exercise.inhaleSeconds;
        _breathController.duration = Duration(seconds: duration);
        _breathController.forward();
        break;
      case 1: // Hold after inhale
        duration = exercise.hold1Seconds;
        break;
      case 2: // Exhale
        duration = exercise.exhaleSeconds;
        _breathController.duration = Duration(seconds: duration);
        _breathController.reverse();
        break;
      case 3: // Hold after exhale
        duration = exercise.hold2Seconds;
        break;
    }

    if (duration == 0) {
      _nextPhase();
      return;
    }

    setState(() {
      _secondsRemaining = duration;
    });

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    if (!_isBreathing) return;

    setState(() {
      _currentPhase++;
      if (_currentPhase > 3) {
        _currentPhase = 0;
        _completedCycles++;

        if (_completedCycles >= _totalCycles) {
          _stopBreathing();
          _showCompletionDialog();
          return;
        }
      }
    });

    _startPhase();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF414345), Color(0xFF232526)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _exercises[_selectedExerciseIndex].color.withOpacity(
                    0.3,
                  ),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    color: _exercises[_selectedExerciseIndex].color,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Great job!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You completed ${_exercises[_selectedExerciseIndex].cycles} cycles',
                    style: TextStyle(color: Colors.grey[300], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _exercises[_selectedExerciseIndex].color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _getPhaseText() {
    switch (_currentPhase) {
      case 0:
        return 'Inhale';
      case 1:
        return 'Hold';
      case 2:
        return 'Exhale';
      case 3:
        return 'Hold';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedExercise = _exercises[_selectedExerciseIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Breathing Exercises',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF414345),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF414345),
              Color(0xFF232526),
              Color.fromARGB(255, 0, 0, 0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Exercise Selection
              if (!_isBreathing) ...[
                Container(
                  height: 140,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      final isSelected = index == _selectedExerciseIndex;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedExerciseIndex = index;
                          });
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isSelected
                                      ? [
                                        exercise.color.withOpacity(0.3),
                                        exercise.color.withOpacity(0.1),
                                      ]
                                      : [
                                        Colors.grey[800]!.withOpacity(0.5),
                                        Colors.grey[900]!.withOpacity(0.5),
                                      ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? exercise.color.withOpacity(0.5)
                                      : Colors.grey[700]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                exercise.icon,
                                color:
                                    isSelected
                                        ? exercise.color
                                        : Colors.grey[400],
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                exercise.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Exercise Details
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[800]!.withOpacity(0.5),
                        Colors.grey[900]!.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            selectedExercise.icon,
                            color: selectedExercise.color,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedExercise.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedExercise.description,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TimingInfo(
                            label: 'Inhale',
                            seconds: selectedExercise.inhaleSeconds,
                            color: selectedExercise.color,
                          ),
                          if (selectedExercise.hold1Seconds > 0)
                            _TimingInfo(
                              label: 'Hold',
                              seconds: selectedExercise.hold1Seconds,
                              color: selectedExercise.color,
                            ),
                          _TimingInfo(
                            label: 'Exhale',
                            seconds: selectedExercise.exhaleSeconds,
                            color: selectedExercise.color,
                          ),
                          if (selectedExercise.hold2Seconds > 0)
                            _TimingInfo(
                              label: 'Hold',
                              seconds: selectedExercise.hold2Seconds,
                              color: selectedExercise.color,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '${selectedExercise.cycles} cycles',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Breathing Animation
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isBreathing) ...[
                        Text(
                          'Cycle ${_completedCycles + 1} of $_totalCycles',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      AnimatedBuilder(
                        animation: _breathAnimation,
                        builder: (context, child) {
                          return Container(
                            width:
                                200 *
                                (_isBreathing ? _breathAnimation.value : 0.6),
                            height:
                                200 *
                                (_isBreathing ? _breathAnimation.value : 0.6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  selectedExercise.color.withOpacity(0.3),
                                  selectedExercise.color.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.7, 1.0],
                              ),
                              border: Border.all(
                                color: selectedExercise.color.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isBreathing) ...[
                                    Text(
                                      _getPhaseText(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$_secondsRemaining',
                                      style: TextStyle(
                                        color: selectedExercise.color,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ] else ...[
                                    Icon(
                                      Icons.air_rounded,
                                      color: selectedExercise.color,
                                      size: 64,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      if (_isBreathing) ...[
                        const SizedBox(height: 40),
                        // Progress indicator
                        Container(
                          width: 200,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _completedCycles / _totalCycles,
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedExercise.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Control Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _isBreathing ? _stopBreathing : _startBreathing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isBreathing
                            ? Colors.red.withOpacity(0.8)
                            : selectedExercise.color,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isBreathing
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isBreathing ? 'Stop' : 'Start Breathing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimingInfo extends StatelessWidget {
  final String label;
  final int seconds;
  final Color color;

  const _TimingInfo({
    required this.label,
    required this.seconds,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          '${seconds}s',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class BreathingExercise {
  final String name;
  final String description;
  final int inhaleSeconds;
  final int hold1Seconds;
  final int exhaleSeconds;
  final int hold2Seconds;
  final int cycles;
  final Color color;
  final IconData icon;

  BreathingExercise({
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.hold1Seconds,
    required this.exhaleSeconds,
    required this.hold2Seconds,
    required this.cycles,
    required this.color,
    required this.icon,
  });
}
