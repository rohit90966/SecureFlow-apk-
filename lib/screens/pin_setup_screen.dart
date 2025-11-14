import 'package:flutter/material.dart';
import '../services/app_pin_service.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isInitialSetup;
  final Function(bool)? onSetupComplete; // Add this callback

  const PinSetupScreen({
    super.key,
    this.isInitialSetup = false,
    this.onSetupComplete
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final AppPinService _pinService = AppPinService();
  final List<String> _enteredPin = [];
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // Color Theme
  final Color _primaryColor = const Color(0xFF007AFF);
  final Color _backgroundColor = const Color(0xFFF4F4F9);
  final Color _textColor = const Color(0xFF1C1C1E);
  final Color _successColor = const Color(0xFF34C759);
  final Color _dangerColor = const Color(0xFFFF3B30);

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _processPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _errorMessage = '';
      });
    }
  }

  void _processPin() async {
    if (!_isConfirming) {
      // First PIN entry
      setState(() {
        _confirmPin = _enteredPin.join();
        _enteredPin.clear();
        _isConfirming = true;
        _errorMessage = '';
      });
    } else {
      // Confirm PIN entry
      final enteredPin = _enteredPin.join();
      if (enteredPin == _confirmPin) {
        setState(() {
          _isLoading = true;
        });

        final success = await _pinService.setPin(enteredPin);

        if (success && mounted) {
          // Call the callback if provided
          if (widget.onSetupComplete != null) {
            widget.onSetupComplete!(true);
          } else {
            // Fallback navigation
            Navigator.of(context).pop(true);
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to set PIN. Please try again.';
            _isLoading = false;
            _resetPin();
          });
        }
      } else {
        setState(() {
          _errorMessage = 'PINs do not match. Please try again.';
          _resetPin();
        });
      }
    }
  }

  void _resetPin() {
    setState(() {
      _enteredPin.clear();
      _confirmPin = '';
      _isConfirming = false;
    });
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
        onPressed: () => _onNumberPressed(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _textColor,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: widget.isInitialSetup
          ? null
          : AppBar(
        title: const Text('Set App PIN'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onSetupComplete != null) {
              widget.onSetupComplete!(false);
            } else {
              Navigator.of(context).pop(false);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isInitialSetup) ...[
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock,
                      size: 64,
                      color: _primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Secure Vault',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your app PIN',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 40),
            Expanded(
              child: Padding(
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
                    Text(
                      _isConfirming ? 'Confirm your PIN' : 'Enter your PIN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConfirming
                          ? 'Re-enter your 4-digit PIN to confirm'
                          : 'Create a 4-digit PIN to secure your app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildPinDots(),
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
                    const Spacer(),
                    // Number Pad
                    Column(
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
                                onPressed: _onBackspacePressed,
                                icon: Icon(
                                  Icons.backspace_outlined,
                                  color: _enteredPin.isEmpty ? Colors.grey.shade400 : _textColor,
                                  size: 24,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(20),
                                  elevation: 2,
                                  shadowColor: Colors.black.withOpacity(0.1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.isInitialSetup) ...[
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          // Skip PIN setup
                          if (widget.onSetupComplete != null) {
                            widget.onSetupComplete!(false);
                          } else {
                            Navigator.of(context).pop(false);
                          }
                        },
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
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