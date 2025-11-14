import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

class AppLockSetupScreen extends StatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen> {
  final AppLockService _lockService = AppLockService();
  String _selectedLockType = AppLockService.lockTypePIN;
  List<String> _enteredPIN = [];
  List<String> _confirmedPIN = [];
  List<int> _enteredPattern = [];
  List<int> _confirmedPattern = [];
  bool _isSetupStage = true;
  String _errorMessage = '';
  int _selectedTimeout = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final timeout = await _lockService.getLockTimeout();
    setState(() {
      _selectedTimeout = timeout;
    });
  }

  void _onPINDigitPressed(String digit) {
    if (_enteredPIN.length >= 4) return;

    setState(() {
      if (_isSetupStage) {
        _enteredPIN.add(digit);
      } else {
        _confirmedPIN.add(digit);
      }
      _errorMessage = '';
    });

    if (_isSetupStage && _enteredPIN.length == 4) {
      _proceedToConfirmation();
    } else if (!_isSetupStage && _confirmedPIN.length == 4) {
      _completePINSetup();
    }
  }

  void _onPINDelete() {
    setState(() {
      if (_isSetupStage) {
        if (_enteredPIN.isNotEmpty) _enteredPIN.removeLast();
      } else {
        if (_confirmedPIN.isNotEmpty) _confirmedPIN.removeLast();
      }
      _errorMessage = '';
    });
  }

  void _proceedToConfirmation() {
    setState(() {
      _isSetupStage = false;
      _errorMessage = '';
    });
  }

  Future<void> _completePINSetup() async {
    if (_enteredPIN.join('') != _confirmedPIN.join('')) {
      setState(() {
        _errorMessage = 'PINs do not match';
        _enteredPIN.clear();
        _confirmedPIN.clear();
        _isSetupStage = true;
      });
      return;
    }

    final success = await _lockService.enablePINLock(_enteredPIN.join(''));
    if (success) {
      await _lockService.setLockTimeout(_selectedTimeout);
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = 'Failed to setup PIN lock';
        _enteredPIN.clear();
        _confirmedPIN.clear();
        _isSetupStage = true;
      });
    }
  }

  void _onPatternPointPressed(int point) {
    if ((_isSetupStage ? _enteredPattern : _confirmedPattern).contains(point)) return;

    setState(() {
      if (_isSetupStage) {
        _enteredPattern.add(point);
      } else {
        _confirmedPattern.add(point);
      }
      _errorMessage = '';
    });
  }

  void _completePatternSetup() {
    if (_enteredPattern.length != _confirmedPattern.length) {
      setState(() {
        _errorMessage = 'Patterns do not match';
        _enteredPattern.clear();
        _confirmedPattern.clear();
        _isSetupStage = true;
      });
      return;
    }

    for (int i = 0; i < _enteredPattern.length; i++) {
      if (_enteredPattern[i] != _confirmedPattern[i]) {
        setState(() {
          _errorMessage = 'Patterns do not match';
          _enteredPattern.clear();
          _confirmedPattern.clear();
          _isSetupStage = true;
        });
        return;
      }
    }

    _lockService.enablePatternLock(_enteredPattern).then((success) {
      if (success) {
        _lockService.setLockTimeout(_selectedTimeout);
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Failed to setup pattern lock';
          _enteredPattern.clear();
          _confirmedPattern.clear();
          _isSetupStage = true;
        });
      }
    });
  }

  Widget _buildPINSetup() {
    return Column(
      children: [
        Text(
          _isSetupStage ? 'Set up your PIN' : 'Confirm your PIN',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 20),

        // PIN Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final currentPIN = _isSetupStage ? _enteredPIN : _confirmedPIN;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < currentPIN.length ? Colors.blue : Colors.grey[300],
              ),
            );
          }),
        ),
        const SizedBox(height: 40),

        // PIN Pad
        _buildPINPad(),
      ],
    );
  }

  Widget _buildPatternSetup() {
    return Column(
      children: [
        Text(
          _isSetupStage ? 'Draw your pattern' : 'Confirm your pattern',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 20),

        // Pattern Grid
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[50],
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return _buildPatternPoint(index + 1);
            },
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        if (!_isSetupStage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _confirmedPattern.clear();
                  });
                },
                child: const Text('Redraw'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _completePatternSetup,
                child: const Text('Confirm'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPINPad() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) {
          return const SizedBox.shrink();
        } else if (index == 10) {
          return _buildPINButton('0');
        } else if (index == 11) {
          return IconButton(
            icon: const Icon(Icons.backspace),
            onPressed: _onPINDelete,
            color: Colors.grey,
          );
        } else {
          return _buildPINButton((index + 1).toString());
        }
      },
    );
  }

  Widget _buildPINButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: () => _onPINDigitPressed(digit),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatternPoint(int point) {
    final currentPattern = _isSetupStage ? _enteredPattern : _confirmedPattern;
    final isSelected = currentPattern.contains(point);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => _onPatternPointPressed(point),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.blue : Colors.grey[300],
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              point.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Lock Setup'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (timeout) {
              setState(() {
                _selectedTimeout = timeout;
              });
            },
            itemBuilder: (context) {
              return AppLockService.timeoutOptions.map((timeout) {
                return PopupMenuItem<int>(
                  value: timeout,
                  child: Text(timeout == 0 ? 'Always lock' : 'Lock after $timeout minutes'),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined),
                  const SizedBox(width: 4),
                  Text(_selectedTimeout == 0 ? 'Always' : '$_selectedTimeout min'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Lock Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lock Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.pin_outlined),
                            title: const Text('PIN'),
                            trailing: Radio<String>(
                              value: AppLockService.lockTypePIN,
                              groupValue: _selectedLockType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLockType = value!;
                                  _enteredPIN.clear();
                                  _confirmedPIN.clear();
                                  _enteredPattern.clear();
                                  _confirmedPattern.clear();
                                  _isSetupStage = true;
                                  _errorMessage = '';
                                });
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.pattern_outlined),
                            title: const Text('Pattern'),
                            trailing: Radio<String>(
                              value: AppLockService.lockTypePattern,
                              groupValue: _selectedLockType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLockType = value!;
                                  _enteredPIN.clear();
                                  _confirmedPIN.clear();
                                  _enteredPattern.clear();
                                  _confirmedPattern.clear();
                                  _isSetupStage = true;
                                  _errorMessage = '';
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Setup Interface
            Expanded(
              child: _selectedLockType == AppLockService.lockTypePIN
                  ? _buildPINSetup()
                  : _buildPatternSetup(),
            ),
          ],
        ),
      ),
    );
  }
}