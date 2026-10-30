import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const TrickOrTreatApp());
}

class TrickOrTreatApp extends StatelessWidget {
  const TrickOrTreatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trick or Treat Busters!',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A0926),
        primaryColor: const Color(0xFFFF6600),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6600),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF2D1242),
        ),
        fontFamily: 'monospace',
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum GameState { ready, playing, gameOver }

class ChildVisitor {
  final String characterEmoji;
  final String requiredItem;

  ChildVisitor({required this.characterEmoji, required this.requiredItem});
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double gameDuration = 10.0;
  
  final List<Map<String, dynamic>> availableItems = [
    {'emoji': '🍬', 'label': 'キャンディ', 'color': Colors.pinkAccent, 'key1': LogicalKeyboardKey.digit1, 'key2': LogicalKeyboardKey.keyA},
    {'emoji': '🎃', 'label': 'カボチャ',   'color': Colors.orangeAccent, 'key1': LogicalKeyboardKey.digit2, 'key2': LogicalKeyboardKey.keyS},
    {'emoji': '👻', 'label': 'おばけ',     'color': Colors.purpleAccent, 'key1': LogicalKeyboardKey.digit3, 'key2': LogicalKeyboardKey.keyD},
    {'emoji': '🍫', 'label': 'チョコ',     'color': Colors.brown, 'key1': LogicalKeyboardKey.digit4, 'key2': LogicalKeyboardKey.keyF},
    {'emoji': '🍪', 'label': 'クッキー',   'color': Colors.amber, 'key1': LogicalKeyboardKey.digit5, 'key2': LogicalKeyboardKey.keyG},
    {'emoji': '🧁', 'label': 'ケーキ',     'color': Colors.tealAccent, 'key1': LogicalKeyboardKey.digit6, 'key2': LogicalKeyboardKey.keyH},
  ];

  GameState _gameState = GameState.ready;
  double _timeLeft = gameDuration;
  int _score = 0;
  Timer? _timer;

  List<ChildVisitor> _children = [];
  final Random _random = Random();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _timer?.cancel();
    setState(() {
      _gameState = GameState.playing;
      _timeLeft = gameDuration;
      _score = 0;
      _children.clear();
      _generateChildren(4);
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _timeLeft -= 0.1;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _gameState = GameState.gameOver;
    });
  }

  void _generateChildren(int count) {
    _children = List.generate(count, (index) {
      final randomItem = availableItems[_random.nextInt(availableItems.length)];
      return ChildVisitor(
        characterEmoji: ['👦', '👧', '🧒', '👶', '🧙', '🦇'][_random.nextInt(6)],
        requiredItem: randomItem['emoji'] as String,
      );
    });
  }

  void _onItemPressed(String tappedItem) {
    if (_gameState != GameState.playing) return;
    if (_children.isEmpty) return;

    if (_children.first.requiredItem == tappedItem) {
      setState(() {
        _score++;
        _children.removeAt(0);
        final randomItem = availableItems[_random.nextInt(availableItems.length)];
        _children.add(
          ChildVisitor(
            characterEmoji: ['👦', '👧', '🧒', '👶', '🧙', '🦇'][_random.nextInt(6)],
            requiredItem: randomItem['emoji'] as String,
          ),
        );
      });
    }
  }

  // X（旧Twitter）で結果をシェアする関数
  Future<void> _shareToX() async {
    final message = Uri.encodeComponent(
      '🎃 Trick or Treat Busters! 👻\n'
      '制限時間10秒で $_score 人の子どもたちをハッピーハロウィンしたよ！\n'
      '#トリックオアトリートバスターズ #Flutterミニゲーム'
    );
    final url = Uri.parse('https://twitter.com/intent/tweet?text=$message');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && _gameState == GameState.playing) {
      for (var item in availableItems) {
        if (event.logicalKey == item['key1'] || event.logicalKey == item['key2']) {
          _onItemPressed(item['emoji'] as String);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '🎃 Trick or Treat Busters! 👻',
                style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 2),
              Text(
                '〜 期間限定公開中 〜',
                style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF12041C),
          toolbarHeight: 56,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // --- 1. 上部：スコアとタイマー ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1242),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent, width: 2),
                      ),
                      child: Text(
                        'スコア: $_score人',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1242),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _timeLeft <= 3.0 ? Colors.redAccent : Colors.purpleAccent, width: 2),
                      ),
                      child: Text(
                        '残り時間: ${_timeLeft.toStringAsFixed(1)}秒',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _timeLeft <= 3.0 ? Colors.redAccent : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _timeLeft / gameDuration,
                  color: const Color(0xFFFF6600),
                  backgroundColor: Colors.black45,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 8),

                // --- 2. 中央：縦のレーン ---
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF220D33),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF6600).withValues(alpha: 0.6), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: _buildVerticalLaneContent(),
                  ),
                ),

                const SizedBox(height: 8),

                // --- 3. 下部：コントローラー（ボタン） ---
                if (_gameState == GameState.playing) ...[
                  const Text(
                    'キーボード: [1]~[6] または [A]~[H]',
                    style: TextStyle(fontSize: 11, color: Colors.orangeAccent),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: availableItems.map((item) {
                      return _buildItemButton(
                        item['emoji'] as String,
                        item['label'] as String,
                        item['color'] as Color,
                      );
                    }).toList(),
                  ),
                ] else ...[
                  _buildStartOrGameOverPanel(),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalLaneContent() {
    if (_gameState == GameState.ready) {
      return const Center(
        child: Text(
          '🎃 お菓子をねだる子どもたちがやってくる！ 👻\n下のボタンを押してゲームスタート！',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _children.asMap().entries.map((entry) {
        int index = entry.key;
        ChildVisitor child = entry.value;
        bool isFirst = index == 0;
        bool isSecond = index == 1;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: isFirst
                ? const Color(0xFFFF6600).withValues(alpha: 0.25)
                : (isSecond ? Colors.purple.withValues(alpha: 0.2) : Colors.black26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFirst
                  ? const Color(0xFFFF6600)
                  : (isSecond ? Colors.purpleAccent.withValues(alpha: 0.5) : Colors.transparent),
              width: isFirst ? 2.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 110,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: isFirst
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6600),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '🔥 先頭！',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        )
                      : (isSecond
                          ? const Text(
                              '👀 次の子...', // アイコンを削除してシンプルに
                              style: TextStyle(fontSize: 12, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                            )
                          : const Text(
                              'まっててね',
                              style: TextStyle(fontSize: 11, color: Colors.white30),
                            )),
                ),
              ),
              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B1855),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  child.requiredItem,
                  style: TextStyle(fontSize: isFirst ? 26 : 18),
                ),
              ),
              const SizedBox(width: 16),

              Text(
                child.characterEmoji,
                style: TextStyle(fontSize: isFirst ? 38 : 26),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemButton(String emoji, String label, Color color) {
    return SizedBox(
      width: 90,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
        ),
        onPressed: () => _onItemPressed(emoji),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 1),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildStartOrGameOverPanel() {
    bool isGameOver = _gameState == GameState.gameOver;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D1242),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purpleAccent, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGameOver) ...[
            const Text(
              '⏰ タイムアップ！ ⏰',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 2),
            Text(
              'スコア: $_score 人ハッピーハロウィン！',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _shareToX,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('結果をシェア', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _startGame,
                  child: const Text('もう一度', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6600),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _startGame,
              child: const Text(
                'ゲームスタート！',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}