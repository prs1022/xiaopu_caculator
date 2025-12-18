import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const XiaopuCalculatorApp());
}

class XiaopuCalculatorApp extends StatelessWidget {
  const XiaopuCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '小浦计算器',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _currentInput = '0';
  final List<String> _history = [];
  bool _showMenu = false;
  bool _isError = false;
  bool _justCalculated = false; // 标记是否刚刚完成计算
  bool _showFontSizeSlider = false; // 是否显示字体大小调节器
  double _fontSize = 24.0; // 当前字体大小
  bool _showSoundModeOptions = false; // 是否显示声音模式选项
  String _soundMode = '无声'; // 当前声音模式：无声、滴滴、哒哒、人声
  final AudioPlayer _beepPlayer = AudioPlayer(); // 滴滴声播放器
  final AudioPlayer _clickPlayer = AudioPlayer(); // 哒哒声播放器
  final AudioPlayer _voicePlayer = AudioPlayer(); // 人声播放器
  bool _audioInitialized = false; // 音频是否已初始化

  @override
  void initState() {
    super.initState();
    // 延迟初始化音频，避免阻塞UI
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeAudio();
    });
  }

  @override
  void dispose() {
    // 释放音频播放器资源
    _beepPlayer.dispose();
    _clickPlayer.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  // 检查字符是否为运算符
  bool _isOperator(String char) {
    return ['+', '-', '×', '÷'].contains(char);
  }

  // 获取输入字符串的最后一个字符
  String _getLastChar(String input) {
    return input.isEmpty ? '' : input[input.length - 1];
  }

  // 初始化音频播放器
  Future<void> _initializeAudio() async {
    if (_audioInitialized) return;

    try {
      // 设置播放器模式为低延迟
      await _beepPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _clickPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _voicePlayer.setPlayerMode(PlayerMode.lowLatency);

      // 设置释放模式
      await _beepPlayer.setReleaseMode(ReleaseMode.stop);
      await _clickPlayer.setReleaseMode(ReleaseMode.stop);
      await _voicePlayer.setReleaseMode(ReleaseMode.stop);

      // 预加载音频文件
      await _beepPlayer.setSource(AssetSource('sounds/beep.mp3'));
      await _clickPlayer.setSource(AssetSource('sounds/click.mp3'));

      _audioInitialized = true;
      print('音频初始化完成');
    } catch (e) {
      print('音频初始化失败: $e');
    }
  }

  // 播放按键声音
  Future<void> _playSound(String key) async {
    if (_soundMode == '无声') return;

    // 确保音频已初始化
    if (!_audioInitialized) {
      await _initializeAudio();
    }

    try {
      if (_soundMode == '滴滴') {
        // 使用专用的beep播放器，无需重新加载
        await _beepPlayer.stop();
        await _beepPlayer.resume();

        // 设置定时器，0.3秒后自动停止播放
        Future.delayed(const Duration(milliseconds: 300), () {
          _beepPlayer.stop();
        });
      } else if (_soundMode == '哒哒') {
        // 使用专用的click播放器，无需重新加载
        await _clickPlayer.stop();
        await _clickPlayer.resume();

        Future.delayed(const Duration(milliseconds: 300), () {
          _clickPlayer.stop();
        });
      } else if (_soundMode == '人声') {
        String voiceFile = _getVoiceFile(key);
        if (voiceFile.isNotEmpty) {
          // 人声使用独立播放器，每次加载不同文件
          await _voicePlayer.stop();
          await _voicePlayer.play(AssetSource('sounds/$voiceFile'));
        }
      }
    } catch (e) {
      print('播放声音失败: $e');
      // 如果播放失败，尝试重新初始化
      _audioInitialized = false;
    }
  }

  // 获取对应的人声文件名
  String _getVoiceFile(String key) {
    switch (key) {
      case '0':
        return 'voice_0.mp3';
      case '1':
        return 'voice_1.mp3';
      case '2':
        return 'voice_2.mp3';
      case '3':
        return 'voice_3.mp3';
      case '4':
        return 'voice_4.mp3';
      case '5':
        return 'voice_5.mp3';
      case '6':
        return 'voice_6.mp3';
      case '7':
        return 'voice_7.mp3';
      case '8':
        return 'voice_8.mp3';
      case '9':
        return 'voice_9.mp3';
      case '+':
        return 'voice_plus.mp3';
      case '-':
        return 'voice_minus.mp3';
      case '×':
        return 'voice_multiply.mp3';
      case '÷':
        return 'voice_divide.mp3';
      case '=':
        return 'voice_equals.mp3';
      case '.':
        return 'voice_dot.mp3';
      case 'C':
        return 'voice_clear.mp3';
      case '⌫':
        return 'voice_delete.mp3';
      default:
        return '';
    }
  }

  void _onButtonPressed(String value) {
    // 播放按键声音
    _playSound(value);

    setState(() {
      if (value == 'C') {
        _currentInput = '0';
        _isError = false;
        _justCalculated = false;
      } else if (value == '=') {
        try {
          final result = _calculateExpression(_currentInput);
          if (result.isInfinite) {
            _currentInput = '不能除以0';
            _isError = true;
            _justCalculated = false;
          } else {
            _history.add('$_currentInput = $result');
            _currentInput = result.toString();
            _isError = false;
            _justCalculated = true; // 标记刚刚完成计算
          }
        } catch (e) {
          print('计算错误: $e, 表达式: $_currentInput');
          _currentInput = 'Error';
          _isError = true;
          _justCalculated = false;
        }
      } else if (value == '⌫') {
        if (_isError) {
          _currentInput = '0';
          _isError = false;
        } else if (_currentInput.length > 1) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        } else {
          _currentInput = '0';
        }
        _justCalculated = false;
      } else if (_isOperator(value)) {
        // 处理运算符输入
        if (_isError) {
          // 如果当前是错误状态，忽略运算符输入
          return;
        }

        // 如果刚刚完成计算，运算符可以基于结果继续计算
        if (_justCalculated) {
          _currentInput += value;
          _justCalculated = false;
          return;
        }

        String lastChar = _getLastChar(_currentInput);

        if (_isOperator(lastChar)) {
          // 如果最后一个字符已经是运算符
          if (lastChar != value) {
            // 如果是不同的运算符，替换最后一个运算符
            _currentInput =
                _currentInput.substring(0, _currentInput.length - 1) + value;
          }
          // 如果是相同的运算符，忽略输入（不做任何操作）
        } else {
          // 如果最后一个字符不是运算符，可以添加运算符
          if (_currentInput == '0') {
            // 如果当前输入是0，只允许负号（用于输入负数）
            if (value == '-') {
              _currentInput = value;
            }
            return;
          }
          _currentInput += value;
        }
      } else {
        // 处理数字和小数点输入
        if (_justCalculated) {
          // 如果刚刚完成计算，数字输入开始新的计算
          _currentInput = value;
          _justCalculated = false;
        } else if (_isError || (_currentInput == '0' && value != '.')) {
          _currentInput = value;
          _isError = false;
        } else {
          _currentInput += value;
        }
      }
    });
  }

  double _calculateExpression(String expression) {
    print('开始计算表达式: $expression');

    // 简单的计算器逻辑
    expression = expression.replaceAll('×', '*').replaceAll('÷', '/');

    // 检查表达式是否以运算符结尾，如果是则自动补充合适的数字
    String lastChar = expression.isNotEmpty
        ? expression[expression.length - 1]
        : '';
    if (['+', '-', '*', '/'].contains(lastChar)) {
      print('表达式以运算符结尾: $expression，自动补充数字');
      if (['+', '-'].contains(lastChar)) {
        // 加减运算符结尾，补充0
        expression += '0';
      } else if (['*', '/'].contains(lastChar)) {
        // 乘除运算符结尾，补充1
        expression += '1';
      }
      print('补充后的表达式: $expression');
    }

    // 简单的单运算符计算
    // 按优先级处理：先乘除，后加减
    for (String op in ['*', '/', '+', '-']) {
      // 从右往左找运算符
      // 对于减号，需要特别处理：如果在开头，那就是负号，不是运算符
      for (int i = expression.length - 1; i >= 0; i--) {
        if (expression[i] == op) {
          // 如果是减号且在开头，跳过（这是负号）
          if (op == '-' && i == 0) {
            continue;
          }

          final left = expression.substring(0, i);
          final right = expression.substring(i + 1);

          print('找到运算符 $op 在位置 $i, 左边: "$left", 右边: "$right"');

          if (left.isEmpty || right.isEmpty) {
            print('左边或右边为空，跳过');
            continue;
          }

          try {
            final leftValue = _calculateExpression(left);
            final rightValue = _calculateExpression(right);

            switch (op) {
              case '+':
                return leftValue + rightValue;
              case '-':
                return leftValue - rightValue;
              case '*':
                return leftValue * rightValue;
              case '/':
                if (rightValue == 0) {
                  return double.infinity;
                }
                return leftValue / rightValue;
            }
          } catch (e) {
            print('解析数字失败: left="$left", right="$right", error=$e');
            continue;
          }
        }
      }
    }

    // 如果没有运算符，直接解析数字
    print('解析数字: $expression');
    return double.parse(expression);
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  void _sumHistory() {
    if (_history.isEmpty) return;

    double sum = 0;
    for (String record in _history) {
      final parts = record.split(' = ');
      if (parts.length == 2) {
        try {
          sum += double.parse(parts[1]);
        } catch (e) {
          // 忽略无法解析的记录
        }
      }
    }
    setState(() {
      _currentInput = sum.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('小浦计算器'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _showMenu = !_showMenu;
            });
          },
        ),
        backgroundColor: Colors.blue[50],
      ),
      body: Column(
        children: [
          // 菜单栏
          if (_showMenu) _buildMenuPanel(),

          // 上层：历史记录
          Expanded(flex: 2, child: _buildHistoryPanel()),

          // 中层：当前输入显示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                horizontal: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              _currentInput,
              style: TextStyle(
                fontSize: _fontSize + 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // 下层：键盘
          Expanded(flex: 3, child: _buildKeyboard()),
        ],
      ),
    );
  }

  Widget _buildMenuPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              _buildMenuButton('声音模式', Icons.volume_up),
              _buildMenuButton('皮肤颜色', Icons.palette),
              _buildMenuButton('字体大小', Icons.text_fields),
              _buildMenuButton('显示日期', Icons.date_range),
              _buildMenuButton('小数位数', Icons.settings),
              _buildMenuButton('语言设置', Icons.language),
            ],
          ),
          const SizedBox(height: 10),
          // 字体大小滑动条
          if (_showFontSizeSlider) ...[
            const Text(
              '字体大小调节',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('小', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 16.0,
                    max: 36.0,
                    divisions: 10,
                    label: _fontSize.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                ),
                const Text('大', style: TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // 声音模式选项
          if (_showSoundModeOptions) ...[
            const Text(
              '声音模式选择',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['无声', '滴滴', '哒哒', '人声'].map((mode) {
                return ChoiceChip(
                  label: Text(mode),
                  selected: _soundMode == mode,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _soundMode = mode;
                      });
                      // 播放示例声音
                      if (mode != '无声') {
                        _playSound('1'); // 播放数字1作为示例
                      }
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 实现登录功能
            },
            icon: const Icon(Icons.login),
            label: const Text('登录'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String title, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          if (title == '字体大小') {
            _showFontSizeSlider = !_showFontSizeSlider;
            _showSoundModeOptions = false; // 关闭其他选项
          } else if (title == '声音模式') {
            _showSoundModeOptions = !_showSoundModeOptions;
            _showFontSizeSlider = false; // 关闭其他选项
          } else {
            // TODO: 实现其他设置功能
          }
        });
      },
      icon: Icon(icon, size: 16),
      label: Text(title, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        backgroundColor:
            (title == '字体大小' && _showFontSizeSlider) ||
                (title == '声音模式' && _showSoundModeOptions)
            ? Colors.blue[200]
            : null,
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('历史记录', style: TextStyle(fontWeight: FontWeight.bold)),
              if (_history.isNotEmpty)
                Row(
                  children: [
                    TextButton(
                      onPressed: _clearHistory,
                      child: const Text('清空'),
                    ),
                    TextButton(onPressed: _sumHistory, child: const Text('求和')),
                  ],
                ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _history[index],
                    style: TextStyle(
                      fontSize: _fontSize - 6,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 第一行: C ⌫ ÷ ×
          Expanded(
            child: Row(
              children: [
                _buildButton('C'),
                _buildButton('⌫'),
                _buildButton('÷'),
                _buildButton('×'),
              ],
            ),
          ),
          // 第二行: 7 8 9 -
          Expanded(
            child: Row(
              children: [
                _buildButton('7'),
                _buildButton('8'),
                _buildButton('9'),
                _buildButton('-'),
              ],
            ),
          ),
          // 第三行: 4 5 6 +
          Expanded(
            child: Row(
              children: [
                _buildButton('4'),
                _buildButton('5'),
                _buildButton('6'),
                _buildButton('+'),
              ],
            ),
          ),
          // 第四和第五行: 使用 Expanded(flex: 2) 来创建两行的空间
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // 左侧三列: 1 2 3 在上行, 0(占两列) . 在下行
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // 上半部分: 1 2 3
                      Expanded(
                        child: Row(
                          children: [
                            _buildButton('1'),
                            _buildButton('2'),
                            _buildButton('3'),
                          ],
                        ),
                      ),
                      // 下半部分: 0(占两列) .
                      Expanded(
                        child: Row(
                          children: [
                            // 0 按钮占据两列宽度
                            Expanded(
                              flex: 2,
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                child: ElevatedButton(
                                  onPressed: () => _onButtonPressed('0'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                  ),
                                  child: Text(
                                    '0',
                                    style: TextStyle(
                                      fontSize: _fontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildButton('.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧一列: = 按钮占据两行高度
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    height: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _onButtonPressed('='),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(20),
                        minimumSize: const Size(
                          double.infinity,
                          double.infinity,
                        ),
                      ),
                      child: Text(
                        '=',
                        style: TextStyle(
                          fontSize: _fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String button) {
    Color? buttonColor;
    Color? textColor;

    if (['C', '⌫'].contains(button)) {
      buttonColor = Colors.red[100];
      textColor = Colors.red[700];
    } else if (['÷', '×', '-', '+', '='].contains(button)) {
      buttonColor = Colors.blue[100];
      textColor = Colors.blue[700];
    } else {
      buttonColor = Colors.grey[200];
      textColor = Colors.black87;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _onButtonPressed(button),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(20),
          ),
          child: Text(
            button,
            style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
