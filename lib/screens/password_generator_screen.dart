// import 'package:flutter/material.dart';
// import 'dart:math';
//
// class PasswordGeneratorScreen extends StatefulWidget {
//   const PasswordGeneratorScreen({super.key});
//
//   @override
//   State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
// }
//
// class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
//   String _generatedPassword = '';
//   int _passwordLength = 16;
//   bool _includeUppercase = true;
//   bool _includeLowercase = true;
//   bool _includeNumbers = true;
//   bool _includeSymbols = true;
//   final TextEditingController _favoriteController = TextEditingController();
//
//   void _generatePassword() {
//     const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
//     const lowercase = 'abcdefghijklmnopqrstuvwxyz';
//     const numbers = '0123456789';
//     const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
//
//     String charPool = '';
//     if (_includeUppercase) charPool += uppercase;
//     if (_includeLowercase) charPool += lowercase;
//     if (_includeNumbers) charPool += numbers;
//     if (_includeSymbols) charPool += symbols;
//
//     if (charPool.isEmpty) {
//       setState(() {
//         _generatedPassword = 'Select at least one character type';
//       });
//       return;
//     }
//
//     final random = StringBuffer();
//     final rand = Random();
//
//     // Ensure at least one of each selected type
//     if (_includeUppercase) {
//       random.write(uppercase[rand.nextInt(uppercase.length)]);
//     }
//     if (_includeLowercase) {
//       random.write(lowercase[rand.nextInt(lowercase.length)]);
//     }
//     if (_includeNumbers) {
//       random.write(numbers[rand.nextInt(numbers.length)]);
//     }
//     if (_includeSymbols) {
//       random.write(symbols[rand.nextInt(symbols.length)]);
//     }
//
//     // Fill remaining length
//     while (random.length < _passwordLength) {
//       random.write(charPool[rand.nextInt(charPool.length)]);
//     }
//
//     // Shuffle the password
//     final passwordChars = random.toString().split('');
//     passwordChars.shuffle();
//
//     setState(() {
//       _generatedPassword = passwordChars.join();
//     });
//   }
//
//   void _generateFromFavorite() {
//     final favorite = _favoriteController.text;
//     if (favorite.isEmpty) {
//       setState(() {
//         _generatedPassword = 'Enter your favorite word first';
//       });
//       return;
//     }
//
//     const numbers = '0123456789';
//     const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
//
//     String base = favorite + numbers + symbols;
//     final random = StringBuffer();
//     final rand = Random();
//
//     for (int i = 0; i < _passwordLength; i++) {
//       random.write(base[rand.nextInt(base.length)]);
//     }
//
//     final passwordChars = random.toString().split('');
//     passwordChars.shuffle();
//
//     setState(() {
//       _generatedPassword = passwordChars.join();
//     });
//   }
//
//   void _copyToClipboard() {
//     if (_generatedPassword.isNotEmpty && _generatedPassword != 'Select at least one character type' && _generatedPassword != 'Enter your favorite word first') {
//       // For web, we can use a simple approach
//       final textArea = TextAreaElement();
//       textArea.value = _generatedPassword;
//       document.body?.append(textArea);
//       textArea.select();
//       document.execCommand('copy');
//       textArea.remove();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Password copied to clipboard')),
//       );
//     }
//   }
//
//   void _usePassword() {
//     if (_generatedPassword.isNotEmpty && _generatedPassword != 'Select at least one character type' && _generatedPassword != 'Enter your favorite word first') {
//       Navigator.pop(context, _generatedPassword);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Password Generator'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           if (_generatedPassword.isNotEmpty && _generatedPassword != 'Select at least one character type' && _generatedPassword != 'Enter your favorite word first')
//             IconButton(
//               icon: const Icon(Icons.check),
//               onPressed: _usePassword,
//               tooltip: 'Use this password',
//             ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             // Generated Password Display
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Generated Password',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     SelectableText(
//                       _generatedPassword.isEmpty ? 'Generate a password first' : _generatedPassword,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontFamily: 'Monospace',
//                         color: _generatedPassword.isEmpty ? Colors.grey : Colors.black,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         ElevatedButton(
//                           onPressed: _generatedPassword.isEmpty ? null : _copyToClipboard,
//                           child: const Text('Copy'),
//                         ),
//                         ElevatedButton(
//                           onPressed: _generatePassword,
//                           child: const Text('Generate New'),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Password Length
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Password Length: $_passwordLength',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Slider(
//                       value: _passwordLength.toDouble(),
//                       min: 8,
//                       max: 32,
//                       divisions: 24,
//                       onChanged: (value) {
//                         setState(() {
//                           _passwordLength = value.toInt();
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Character Types
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Character Types',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     CheckboxListTile(
//                       title: const Text('Uppercase Letters (A-Z)'),
//                       value: _includeUppercase,
//                       onChanged: (value) {
//                         setState(() {
//                           _includeUppercase = value!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: const Text('Lowercase Letters (a-z)'),
//                       value: _includeLowercase,
//                       onChanged: (value) {
//                         setState(() {
//                           _includeLowercase = value!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: const Text('Numbers (0-9)'),
//                       value: _includeNumbers,
//                       onChanged: (value) {
//                         setState(() {
//                           _includeNumbers = value!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: const Text('Symbols (!@#\$ etc.)'),
//                       value: _includeSymbols,
//                       onChanged: (value) {
//                         setState(() {
//                           _includeSymbols = value!;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Generate from Favorite
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Generate from Favorite Word',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: _favoriteController,
//                       decoration: const InputDecoration(
//                         hintText: 'Enter your favorite word or name',
//                         border: OutlineInputBorder(),
//                         contentPadding: EdgeInsets.all(12),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     ElevatedButton(
//                       onPressed: _generateFromFavorite,
//                       style: ElevatedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                       child: const Text('Generate from Favorite'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Quick Generate Buttons
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Quick Generate',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {
//                               setState(() {
//                                 _passwordLength = 12;
//                                 _generatePassword();
//                               });
//                             },
//                             child: const Text('12 chars'),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {
//                               setState(() {
//                                 _passwordLength = 16;
//                                 _generatePassword();
//                               });
//                             },
//                             child: const Text('16 chars'),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {
//                               setState(() {
//                                 _passwordLength = 20;
//                                 _generatePassword();
//                               });
//                             },
//                             child: const Text('20 chars'),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     // Generate initial password
//     _generatePassword();
//   }
//
//   @override
//   void dispose() {
//     _favoriteController.dispose();
//     super.dispose();
//   }
// }
import 'package:flutter/material.dart';
import 'dart:math';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _generatedPassword = '';
  int _passwordLength = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  final TextEditingController _favoriteController = TextEditingController();

  void _generatePassword() {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String charPool = '';
    if (_includeUppercase) charPool += uppercase;
    if (_includeLowercase) charPool += lowercase;
    if (_includeNumbers) charPool += numbers;
    if (_includeSymbols) charPool += symbols;

    if (charPool.isEmpty) {
      setState(() {
        _generatedPassword = 'Select at least one character type';
      });
      return;
    }

    final random = StringBuffer();
    final rand = Random();

    // Ensure at least one of each selected type
    if (_includeUppercase) {
      random.write(uppercase[rand.nextInt(uppercase.length)]);
    }
    if (_includeLowercase) {
      random.write(lowercase[rand.nextInt(lowercase.length)]);
    }
    if (_includeNumbers) {
      random.write(numbers[rand.nextInt(numbers.length)]);
    }
    if (_includeSymbols) {
      random.write(symbols[rand.nextInt(symbols.length)]);
    }

    // Fill remaining length
    while (random.length < _passwordLength) {
      random.write(charPool[rand.nextInt(charPool.length)]);
    }

    // Shuffle the password
    final passwordChars = random.toString().split('');
    passwordChars.shuffle();

    setState(() {
      _generatedPassword = passwordChars.join();
    });
  }

  void _generateFromFavorite() {
    final favorite = _favoriteController.text;
    if (favorite.isEmpty) {
      setState(() {
        _generatedPassword = 'Enter your favorite word first';
      });
      return;
    }

    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String base = favorite + numbers + symbols;
    final random = StringBuffer();
    final rand = Random();

    for (int i = 0; i < _passwordLength; i++) {
      random.write(base[rand.nextInt(base.length)]);
    }

    final passwordChars = random.toString().split('');
    passwordChars.shuffle();

    setState(() {
      _generatedPassword = passwordChars.join();
    });
  }

  void _copyToClipboard() {
    if (_generatedPassword.isNotEmpty &&
        _generatedPassword != 'Select at least one character type' &&
        _generatedPassword != 'Enter your favorite word first') {
      // For mobile, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password ready to use')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Generator'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Generated Password Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Generated Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _generatedPassword.isEmpty ? 'Generate a password first' : _generatedPassword,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Monospace',
                        color: _generatedPassword.isEmpty ? Colors.grey : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: _generatedPassword.isEmpty ? null : _copyToClipboard,
                          child: const Text('Copy'),
                        ),
                        ElevatedButton(
                          onPressed: _generatePassword,
                          child: const Text('Generate New'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Password Length
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Length: $_passwordLength',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _passwordLength.toDouble(),
                      min: 8,
                      max: 32,
                      divisions: 24,
                      onChanged: (value) {
                        setState(() {
                          _passwordLength = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Character Types
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Character Types',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Uppercase Letters (A-Z)'),
                      value: _includeUppercase,
                      onChanged: (value) {
                        setState(() {
                          _includeUppercase = value!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Lowercase Letters (a-z)'),
                      value: _includeLowercase,
                      onChanged: (value) {
                        setState(() {
                          _includeLowercase = value!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Numbers (0-9)'),
                      value: _includeNumbers,
                      onChanged: (value) {
                        setState(() {
                          _includeNumbers = value!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Symbols (!@#\$ etc.)'),
                      value: _includeSymbols,
                      onChanged: (value) {
                        setState(() {
                          _includeSymbols = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Generate from Favorite
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generate from Favorite Word',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _favoriteController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your favorite word or name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _generateFromFavorite,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Generate from Favorite'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Generate initial password
    _generatePassword();
  }

  @override
  void dispose() {
    _favoriteController.dispose();
    super.dispose();
  }
}