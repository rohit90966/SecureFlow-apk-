import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AppLockService _lockService = AppLockService();
  String _lockType = AppLockService.lockTypeNone;
  List<String> _enteredPIN = [];
  List<int> _enteredPattern = [];
  bool _isVerifying = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeLock();
  }

  Future<void> _initializeLock() async {
    final type = await _lockService.getLockType();
    setState(() {
      _lockType = type;
    });
  }

  void _onPINDigitPressed(String digit) {
    if (_isVerifying || _enteredPIN.length >= 4) return;

    setState(() {
      _enteredPIN.add(digit);
      _errorMessage = '';
    });

    if (_enteredPIN.length == 4) {
      _verifyPIN();
    }
  }

  void _onPINDelete() {
    if (_enteredPIN.isNotEmpty) {
      setState(() {
        _enteredPIN.removeLast();
        _errorMessage = '';
      });
    }
  }

  Future<void> _verifyPIN() async {
    setState(() {
      _isVerifying = true;
    });

    final pin = _enteredPIN.join('');
    final isValid = await _lockService.verifyPIN(pin);

    if (isValid) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _errorMessage = 'Invalid PIN';
        _enteredPIN.clear();
        _isVerifying = false;
      });
    }
  }

  void _onPatternPointPressed(int point) {
    if (_isVerifying || _enteredPattern.contains(point)) return;

    setState(() {
      _enteredPattern.add(point);
      _errorMessage = '';
    });
  }

  Future<void> _verifyPattern() async {
    if (_enteredPattern.length < 4) {
      setState(() {
        _errorMessage = 'Pattern too short';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final isValid = await _lockService.verifyPattern(_enteredPattern);

    if (isValid) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _errorMessage = 'Invalid pattern';
        _enteredPattern.clear();
        _isVerifying = false;
      });
    }
  }

  void _resetInput() {
    setState(() {
      if (_lockType == AppLockService.lockTypePIN) {
        _enteredPIN.clear();
      } else {
        _enteredPattern.clear();
      }
      _errorMessage = '';
      _isVerifying = false;
    });
  }

  Widget _buildPINLock() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
        const SizedBox(height: 20),
        const Text(
          'Enter PIN',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
        const SizedBox(height: 30),

        // PIN Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _enteredPIN.length ? Colors.blue : Colors.grey[300],
              ),
            );
          }),
        ),
        const SizedBox(height: 50),

        // PIN Pad
        GridView.builder(
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
              return const SizedBox.shrink(); // Empty space
            } else if (index == 10) {
              return _buildPINButton('0', onPressed: _onPINDigitPressed);
            } else if (index == 11) {
              return IconButton(
                icon: const Icon(Icons.backspace),
                onPressed: _onPINDelete,
                color: Colors.grey,
              );
            } else {
              return _buildPINButton((index + 1).toString(), onPressed: _onPINDigitPressed);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPINButton(String digit, {required Function(String) onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: () => onPressed(digit),
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

  Widget _buildPatternLock() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.pattern_outlined, size: 80, color: Colors.blue),
        const SizedBox(height: 20),
        const Text(
          'Draw Pattern',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
        const SizedBox(height: 30),

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
        const SizedBox(height: 30),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _resetInput,
              child: const Text('Reset'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _verifyPattern,
              child: const Text('Verify'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatternPoint(int point) {
    final isSelected = _enteredPattern.contains(point);
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _lockType == AppLockService.lockTypePIN
              ? _buildPINLock()
              : _buildPatternLock(),
        ),
      ),
    );
  }
}