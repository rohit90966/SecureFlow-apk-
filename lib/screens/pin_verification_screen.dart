import 'package:flutter/material.dart';
import '../services/app_pin_service.dart';

class PinVerificationScreen extends StatefulWidget {
  final Function(bool)? onVerificationComplete;

  const PinVerificationScreen({super.key, this.onVerificationComplete});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final AppPinService _pinService = AppPinService();
  final List<String> _enteredPin = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLocked = false;
  int _remainingAttempts = 5;

  final Color _primaryColor = const Color(0xFF007AFF);
  final Color _dangerColor = const Color(0xFFFF3B30);
  final Color _warningColor = const Color(0xFFFF9500);

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    final locked = await _pinService.isLocked();
    final attempts = await _pinService.getRemainingAttempts();

    setState(() {
      _isLocked = locked;
      _remainingAttempts = attempts;
    });
  }

  void _onNumberPressed(String number) {
    if (_isLocked) return;

    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_isLocked) return;

    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _errorMessage = '';
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_isLocked) return;

    setState(() {
      _isLoading = true;
    });

    final enteredPin = _enteredPin.join();
    final isCorrect = await _pinService.verifyPin(enteredPin);

    if (isCorrect && mounted) {
      // PIN correct
      setState(() {
        _isLoading = false;
      });

      // Call the callback with success
      if (widget.onVerificationComplete != null) {
        widget.onVerificationComplete!(true);
      } else {
        // Fallback navigation
        Navigator.of(context).pop(true);
      }
    } else {
      // PIN incorrect
      await _checkLockStatus();
      setState(() {
        _isLoading = false;
        _enteredPin.clear();
        _errorMessage = 'Incorrect PIN. $_remainingAttempts attempts remaining.';

        if (_isLocked) {
          _errorMessage = 'Too many failed attempts. Try again in 30 minutes.';
        }
      });
    }
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.length ? _primaryColor : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildNumberButton(String number) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: _isLocked ? null : () => _onNumberPressed(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLocked ? Colors.grey.shade300 : Colors.white,
          foregroundColor: _isLocked ? Colors.grey.shade500 : Colors.black,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
          elevation: 2,
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLockedMessage() {
    return Column(
      children: [
        Icon(
          Icons.lock_clock,
          size: 64,
          color: _warningColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Account Temporarily Locked',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _warningColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Too many incorrect PIN attempts.\nPlease wait 30 minutes and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _checkLockStatus,
          icon: const Icon(Icons.refresh),
          label: const Text('Check Status'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPinPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberButton('1'),
            _buildNumberButton('2'),
            _buildNumberButton('3'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberButton('4'),
            _buildNumberButton('5'),
            _buildNumberButton('6'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberButton('7'),
            _buildNumberButton('8'),
            _buildNumberButton('9'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(8),
              width: 80,
              height: 80,
            ),
            _buildNumberButton('0'),
            Container(
              margin: const EdgeInsets.all(8),
              child: IconButton(
                onPressed: _isLocked ? null : _onBackspacePressed,
                icon: Icon(
                  Icons.backspace_outlined,
                  color: _isLocked ? Colors.grey.shade400 : Colors.black,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _isLocked ? Colors.grey.shade300 : Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F9),
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              title: const Text('Enter PIN'),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: _primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Enter your PIN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Show different messages based on lock status
                    if (_isLocked)
                      _buildLockedMessage()
                    else
                      Column(
                        children: [
                          const Text(
                            'Enter your 4-digit PIN to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildPinDots(),
                        ],
                      ),

                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: _dangerColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      CircularProgressIndicator(color: _primaryColor),
                    ],

                    const SizedBox(height: 32),

                    // Only show PIN pad if not locked
                    if (!_isLocked) _buildPinPad(),
                  ],
                ), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}