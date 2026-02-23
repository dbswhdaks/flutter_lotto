import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

enum GameType {
  lotto,
  pension,
  powerball,
  speedkino,
  megabingo,
  tripleluck,
  doublejack,
  treasure,
  catchme,
}

enum _ToneType { brass, bell, synth, chime, marimba, dark }

class _ThemeData {
  final _ToneType tone;
  final List<double> scale;
  final double rootLow;
  final double rootHigh;
  final double topNote;
  final double ballDecay;
  final double pitchBend;
  final double startDecay;

  const _ThemeData({
    required this.tone,
    required this.scale,
    required this.rootLow,
    required this.rootHigh,
    required this.topNote,
    required this.ballDecay,
    required this.pitchBend,
    required this.startDecay,
  });
}

class _GameSounds {
  String? startPath;
  List<String>? ballPaths;
  String? completePath;
  String? specialPath;
  String? hitPath;
  String? missPath;
  String? bouncePath;
  String? whooshPath;
  String? mixingPath;
}

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final _startPlayer = AudioPlayer();
  final _ballPlayer = AudioPlayer();
  final _completePlayer = AudioPlayer();
  final _specialPlayer = AudioPlayer();
  final _bouncePlayer = AudioPlayer();
  final _whooshPlayer = AudioPlayer();
  final _mixPlayer = AudioPlayer();

  bool _initialized = false;
  GameType _currentGame = GameType.lotto;
  final Map<GameType, _GameSounds> _gameSounds = {};
  late Directory _soundBaseDir;

  static const int _sampleRate = 44100;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getTemporaryDirectory();
      _soundBaseDir = Directory('${dir.path}/lotto_sounds_v9');
      if (!_soundBaseDir.existsSync()) {
        _soundBaseDir.createSync(recursive: true);
      }

      await _startPlayer.setVolume(0.85);
      await _ballPlayer.setVolume(0.9);
      await _completePlayer.setVolume(1.0);
      await _specialPlayer.setVolume(1.0);
      await _bouncePlayer.setVolume(0.7);
      await _whooshPlayer.setVolume(0.6);
      await _mixPlayer.setVolume(0.35);

      _initialized = true;
      await _ensureGameSounds(_currentGame);
    } catch (e) {
      _debugErr('init', e);
    }
  }

  Future<void> setGameType(GameType type) async {
    _currentGame = type;
    await _ensureGameSounds(type);
  }

  Future<void> _ensureGameSounds(GameType type) async {
    if (_gameSounds.containsKey(type)) return;
    try {
      final gameDir = Directory('${_soundBaseDir.path}/${type.name}');
      if (!gameDir.existsSync()) gameDir.createSync(recursive: true);

      final sounds = _GameSounds();
      final theme = _themes[type]!;

      sounds.startPath = '${gameDir.path}/start.wav';
      await File(sounds.startPath!).writeAsBytes(_genStart(type, theme));

      sounds.ballPaths = [];
      for (int i = 0; i < 7; i++) {
        final p = '${gameDir.path}/ball_$i.wav';
        await File(p).writeAsBytes(_genBall(type, theme, i));
        sounds.ballPaths!.add(p);
      }

      sounds.completePath = '${gameDir.path}/complete.wav';
      await File(sounds.completePath!)
          .writeAsBytes(_genComplete(type, theme));

      sounds.specialPath = '${gameDir.path}/special.wav';
      await File(sounds.specialPath!)
          .writeAsBytes(_genSpecial(type, theme));

      sounds.hitPath = '${gameDir.path}/hit.wav';
      await File(sounds.hitPath!).writeAsBytes(_genHit(type, theme));

      sounds.missPath = '${gameDir.path}/miss.wav';
      await File(sounds.missPath!).writeAsBytes(_genMiss(type, theme));

      sounds.bouncePath = '${gameDir.path}/bounce.wav';
      await File(sounds.bouncePath!).writeAsBytes(_genBounce(type, theme));

      sounds.whooshPath = '${gameDir.path}/whoosh.wav';
      await File(sounds.whooshPath!).writeAsBytes(_genWhoosh(type, theme));

      sounds.mixingPath = '${gameDir.path}/mixing.wav';
      await File(sounds.mixingPath!).writeAsBytes(_genMixing(type, theme));

      _gameSounds[type] = sounds;
    } catch (e) {
      _debugErr('_ensureGameSounds(${type.name})', e);
    }
  }

  _GameSounds? get _cs => _gameSounds[_currentGame];

  // ─── Play Methods ────────────────────────────────────

  Future<void> playStart() async {
    if (!_initialized || _cs?.startPath == null) return;
    try {
      await _startPlayer.stop();
      await _startPlayer.play(DeviceFileSource(_cs!.startPath!));
    } catch (e) {
      _debugErr('playStart', e);
    }
  }

  Future<void> playBall(int index) async {
    if (!_initialized || _cs?.ballPaths == null) return;
    try {
      await _ballPlayer.stop();
      await _ballPlayer
          .play(DeviceFileSource(_cs!.ballPaths![index.clamp(0, 6)]));
    } catch (e) {
      _debugErr('playBall', e);
    }
  }

  Future<void> playComplete() async {
    if (!_initialized || _cs?.completePath == null) return;
    try {
      await _completePlayer.stop();
      await _completePlayer.play(DeviceFileSource(_cs!.completePath!));
    } catch (e) {
      _debugErr('playComplete', e);
    }
  }

  Future<void> playSpecial() async {
    if (!_initialized || _cs?.specialPath == null) return;
    try {
      await _specialPlayer.stop();
      await _specialPlayer.play(DeviceFileSource(_cs!.specialPath!));
    } catch (e) {
      _debugErr('playSpecial', e);
    }
  }

  Future<void> playHit() async {
    if (!_initialized || _cs?.hitPath == null) return;
    try {
      await _specialPlayer.stop();
      await _specialPlayer.play(DeviceFileSource(_cs!.hitPath!));
    } catch (e) {
      _debugErr('playHit', e);
    }
  }

  Future<void> playMiss() async {
    if (!_initialized || _cs?.missPath == null) return;
    try {
      await _specialPlayer.stop();
      await _specialPlayer.play(DeviceFileSource(_cs!.missPath!));
    } catch (e) {
      _debugErr('playMiss', e);
    }
  }

  Future<void> playBounce() async {
    if (!_initialized || _cs?.bouncePath == null) return;
    try {
      await _bouncePlayer.stop();
      await _bouncePlayer.play(DeviceFileSource(_cs!.bouncePath!));
    } catch (e) {
      _debugErr('playBounce', e);
    }
  }

  Future<void> playWhoosh() async {
    if (!_initialized || _cs?.whooshPath == null) return;
    try {
      await _whooshPlayer.stop();
      await _whooshPlayer.play(DeviceFileSource(_cs!.whooshPath!));
    } catch (e) {
      _debugErr('playWhoosh', e);
    }
  }

  Future<void> playMixing() async {
    if (!_initialized || _cs?.mixingPath == null) return;
    try {
      await _mixPlayer.setReleaseMode(ReleaseMode.loop);
      await _mixPlayer.play(DeviceFileSource(_cs!.mixingPath!));
    } catch (e) {
      _debugErr('playMixing', e);
    }
  }

  Future<void> stopMixing() async {
    try {
      await _mixPlayer.stop();
    } catch (e) {
      _debugErr('stopMixing', e);
    }
  }

  void _debugErr(String m, Object e) {
    assert(() {
      // ignore: avoid_print
      print('[SoundService.$m] $e');
      return true;
    }());
  }

  // ─── Scales ──────────────────────────────────────────

  static const _cMaj = [130.81, 146.83, 164.81, 174.61, 196.00, 220.00, 246.94];
  static const _ebMaj = [155.56, 174.61, 196.00, 207.65, 233.08, 261.63, 293.66];
  static const _eMin = [164.81, 185.00, 196.00, 220.00, 246.94, 261.63, 293.66];
  static const _aMaj = [220.00, 246.94, 277.18, 293.66, 329.63, 369.99, 415.30];
  static const _gMaj = [196.00, 220.00, 246.94, 261.63, 293.66, 329.63, 369.99];
  static const _dMaj = [146.83, 164.81, 185.00, 196.00, 220.00, 246.94, 277.18];
  static const _bbMin = [116.54, 130.81, 138.59, 155.56, 174.61, 185.00, 207.65];
  static const _cMin = [130.81, 146.83, 155.56, 174.61, 196.00, 207.65, 233.08];
  static const _abMaj = [207.65, 233.08, 261.63, 277.18, 311.13, 349.23, 392.00];

  // ─── Theme Definitions ───────────────────────────────
  //
  // lotto:      C major  · brass  · 클래식 로또 느낌
  // pension:    Eb major · bell   · 우아한 뮤직박스
  // powerball:  E minor  · synth  · 파워풀 일렉트로닉
  // speedkino:  A major  · marimba· 빠른 타격음
  // megabingo:  Ab major · marimba· 통통 튀는 마림바 빙고
  // tripleluck: G major  · bell   · 반짝이는 행운 벨
  // doublejack: D major  · brass  · 웅장한 금관악기
  // treasure:   Bb minor · dark   · 모험적이고 신비로운
  // catchme:    C minor  · synth  · 긴장감 있는 서스펜스

  static final Map<GameType, _ThemeData> _themes = {
    GameType.lotto: const _ThemeData(
      tone: _ToneType.brass, scale: _cMaj,
      rootLow: 65.41, rootHigh: 261.63, topNote: 523.25,
      ballDecay: 14, pitchBend: 0.15, startDecay: 12,
    ),
    GameType.pension: const _ThemeData(
      tone: _ToneType.bell, scale: _ebMaj,
      rootLow: 77.78, rootHigh: 311.13, topNote: 622.25,
      ballDecay: 10, pitchBend: 0.05, startDecay: 8,
    ),
    GameType.powerball: const _ThemeData(
      tone: _ToneType.synth, scale: _eMin,
      rootLow: 82.41, rootHigh: 329.63, topNote: 659.26,
      ballDecay: 18, pitchBend: 0.25, startDecay: 15,
    ),
    GameType.speedkino: const _ThemeData(
      tone: _ToneType.marimba, scale: _aMaj,
      rootLow: 110.00, rootHigh: 440.00, topNote: 880.00,
      ballDecay: 22, pitchBend: 0.08, startDecay: 16,
    ),
    GameType.megabingo: const _ThemeData(
      tone: _ToneType.marimba, scale: _abMaj,
      rootLow: 103.83, rootHigh: 415.30, topNote: 830.61,
      ballDecay: 24, pitchBend: 0.04, startDecay: 12,
    ),
    GameType.tripleluck: const _ThemeData(
      tone: _ToneType.bell, scale: _gMaj,
      rootLow: 98.00, rootHigh: 392.00, topNote: 783.99,
      ballDecay: 12, pitchBend: 0.06, startDecay: 10,
    ),
    GameType.doublejack: const _ThemeData(
      tone: _ToneType.brass, scale: _dMaj,
      rootLow: 73.42, rootHigh: 293.66, topNote: 587.33,
      ballDecay: 12, pitchBend: 0.12, startDecay: 10,
    ),
    GameType.treasure: const _ThemeData(
      tone: _ToneType.dark, scale: _bbMin,
      rootLow: 58.27, rootHigh: 233.08, topNote: 466.16,
      ballDecay: 12, pitchBend: 0.12, startDecay: 9,
    ),
    GameType.catchme: const _ThemeData(
      tone: _ToneType.synth, scale: _cMin,
      rootLow: 65.41, rootHigh: 261.63, topNote: 523.25,
      ballDecay: 20, pitchBend: 0.20, startDecay: 16,
    ),
  };

  // ─── Tone Generators ────────────────────────────────

  double _rawTone(_ToneType type, double t, double freq, double env) {
    switch (type) {
      case _ToneType.brass:
        return (sin(2 * pi * freq * t) +
                sin(2 * pi * freq * 0.5 * t) * 0.35 +
                sin(2 * pi * freq * 2 * t) * 0.20 +
                sin(2 * pi * freq * 3 * t) * 0.10) *
            env;
      case _ToneType.bell:
        return (sin(2 * pi * freq * t) +
                sin(2 * pi * freq * 2.0 * t) * 0.50 +
                sin(2 * pi * freq * 3.01 * t) * 0.30 +
                sin(2 * pi * freq * 4.07 * t) * 0.20 +
                sin(2 * pi * freq * 5.12 * t) * 0.10) *
            env;
      case _ToneType.synth:
        return (sin(2 * pi * freq * t) +
                sin(2 * pi * freq * 3 * t) * 0.33 +
                sin(2 * pi * freq * 5 * t) * 0.20 +
                sin(2 * pi * freq * 0.5 * t) * 0.50) *
            env;
      case _ToneType.chime:
        return (sin(2 * pi * freq * t) +
                sin(2 * pi * freq * 2 * t) * 0.40 +
                sin(2 * pi * freq * 3 * t) * 0.30 +
                sin(2 * pi * freq * 5.04 * t) * 0.20 +
                sin(2 * pi * freq * 7.01 * t) * 0.10 +
                sin(2 * pi * freq * 9 * t) * 0.05) *
            env;
      case _ToneType.marimba:
        return (sin(2 * pi * freq * t) +
                sin(2 * pi * freq * 4 * t) * 0.20 +
                sin(2 * pi * freq * 9.2 * t) * 0.05) *
            env *
            min(1.0, t * 200);
      case _ToneType.dark:
        return (sin(2 * pi * freq * t) +
                sin(2 * pi * freq * 0.5 * t) * 0.30 +
                sin(2 * pi * freq * 0.998 * t) * 0.18 +
                sin(2 * pi * freq * 1.5 * t) * 0.10) *
            env;
    }
  }

  double _toneFor(
      _ToneType type, double t, double freq, double amp, double decay) {
    return _rawTone(type, t, freq, exp(-t * decay) * amp);
  }

  double _impactFor(_ToneType type, double t, double freq, double amp) {
    final env = exp(-t * 25) * amp;
    switch (type) {
      case _ToneType.brass:
      case _ToneType.dark:
        return sin(2 * pi * freq * t * (1.0 + exp(-t * 40) * 3.0)) * env +
            sin(2 * pi * freq * 0.5 * t) * exp(-t * 12) * amp * 0.4;
      case _ToneType.bell:
      case _ToneType.chime:
        return (sin(2 * pi * freq * t) +
                sin(2 * pi * freq * 2.01 * t) * 0.5) *
            env;
      case _ToneType.synth:
        return (sin(2 * pi * freq * t) +
                sin(2 * pi * freq * 0.5 * t) * 0.6) *
            exp(-t * 20) *
            amp;
      case _ToneType.marimba:
        return sin(2 * pi * freq * t) *
            exp(-t * 30) *
            amp *
            min(1.0, t * 500);
    }
  }

  // ─── Start Sound Patterns ───────────────────────────

  List<(double, double)> _startNotes(GameType g, _ThemeData t) {
    final s = t.scale;
    switch (g) {
      case GameType.lotto: // 상행 스케일
        return [
          (0.0, s[0]), (0.10, s[1]), (0.20, s[2]), (0.30, s[3]),
          (0.40, s[4]), (0.50, s[5]), (0.60, s[6]), (0.70, t.rootHigh),
        ];
      case GameType.pension: // 하행 후 상행 (우아한 벨)
        return [
          (0.0, s[6]), (0.13, s[4]), (0.26, s[2]), (0.39, s[0]),
          (0.56, s[2]), (0.69, s[4]), (0.82, s[6]), (0.95, t.rootHigh),
        ];
      case GameType.powerball: // 옥타브 점프 (파워풀)
        return [
          (0.0, s[0]), (0.09, s[0] * 2), (0.20, s[2]), (0.29, s[2] * 2),
          (0.40, s[4]), (0.49, s[4] * 2), (0.60, s[6]), (0.69, t.rootHigh),
        ];
      case GameType.speedkino: // 초고속 상행
        return [
          (0.0, s[0]), (0.06, s[1]), (0.12, s[2]), (0.18, s[3]),
          (0.24, s[4]), (0.30, s[5]), (0.36, s[6]), (0.42, t.rootHigh),
        ];
      case GameType.megabingo: // 바운시 교차 패턴
        return [
          (0.0, s[0]), (0.10, s[4]), (0.20, s[2]), (0.30, s[5]),
          (0.40, s[0]), (0.50, s[3]), (0.60, s[6]), (0.70, t.rootHigh),
        ];
      case GameType.tripleluck: // 3-3-2 럭키 패턴
        return [
          (0.0, s[0]), (0.08, s[2]), (0.16, s[4]),
          (0.28, s[0]), (0.36, s[2]), (0.44, s[4]),
          (0.56, s[5]), (0.64, t.rootHigh),
        ];
      case GameType.doublejack: // 더블노트 위엄
        return [
          (0.0, s[0]), (0.06, s[0]), (0.18, s[2]), (0.24, s[2]),
          (0.36, s[4]), (0.42, s[4]), (0.54, s[5]), (0.66, t.rootHigh),
        ];
      case GameType.treasure: // 하행 후 극적 상행
        return [
          (0.0, s[6]), (0.14, s[4]), (0.28, s[2]), (0.42, s[0]),
          (0.58, s[1]), (0.72, s[3]), (0.86, s[5]), (1.0, t.rootHigh),
        ];
      case GameType.catchme: // 긴장감 리듬 그룹
        return [
          (0.0, s[0]), (0.07, s[0]), (0.14, s[2]),
          (0.25, s[4]), (0.32, s[4]), (0.39, s[6]),
          (0.50, s[4]), (0.57, t.rootHigh),
        ];
    }
  }

  double _startDuration(GameType g) {
    switch (g) {
      case GameType.lotto:
        return 1.0;
      case GameType.pension:
        return 1.3;
      case GameType.powerball:
        return 1.0;
      case GameType.speedkino:
        return 0.7;
      case GameType.megabingo:
        return 1.0;
      case GameType.tripleluck:
        return 0.9;
      case GameType.doublejack:
        return 1.0;
      case GameType.treasure:
        return 1.3;
      case GameType.catchme:
        return 0.85;
    }
  }

  // ─── Complete Melody Per Game ────────────────────────

  List<(double, double, double)> _completeMelody(GameType g, _ThemeData t) {
    final s = t.scale;
    switch (g) {
      case GameType.lotto: // 밝은 브라스 팡파레
        return [
          (0.0, 0.12, s[0] * 2), (0.12, 0.12, s[2] * 2),
          (0.24, 0.12, s[4] * 2), (0.36, 0.12, s[2] * 2),
          (0.48, 0.12, s[4] * 2), (0.60, 0.25, t.topNote),
        ];
      case GameType.pension: // 우아한 벨 아르페지오
        return [
          (0.0, 0.20, s[2] * 2), (0.20, 0.20, s[4] * 2),
          (0.40, 0.30, s[6] * 2), (0.75, 0.20, s[4] * 2),
          (0.95, 0.30, t.topNote),
        ];
      case GameType.powerball: // 파워 코드 히트
        return [
          (0.0, 0.10, s[0] * 2), (0.10, 0.10, s[4] * 2),
          (0.20, 0.15, s[6] * 2), (0.38, 0.10, s[0] * 2),
          (0.48, 0.10, s[4] * 2), (0.58, 0.25, t.topNote),
        ];
      case GameType.speedkino: // 초고속 승리 팡파레
        return [
          (0.0, 0.08, s[0] * 2), (0.08, 0.08, s[2] * 2),
          (0.16, 0.08, s[4] * 2), (0.24, 0.08, s[6] * 2),
          (0.32, 0.20, t.topNote), (0.55, 0.08, s[4] * 2),
          (0.63, 0.15, t.topNote),
        ];
      case GameType.megabingo: // 경쾌한 빙고 멜로디
        return [
          (0.0, 0.12, s[0] * 2), (0.12, 0.12, s[4] * 2),
          (0.24, 0.12, s[0] * 2), (0.36, 0.12, s[2] * 2),
          (0.48, 0.12, s[4] * 2), (0.60, 0.25, t.topNote),
        ];
      case GameType.tripleluck: // 3+3+1 럭키 벨
        return [
          (0.0, 0.10, s[0] * 2), (0.10, 0.10, s[2] * 2),
          (0.20, 0.15, s[4] * 2), (0.38, 0.10, s[0] * 2),
          (0.48, 0.10, s[2] * 2), (0.58, 0.15, s[4] * 2),
          (0.76, 0.25, t.topNote),
        ];
      case GameType.doublejack: // 웅장한 로열 팡파레
        return [
          (0.0, 0.15, s[0] * 2), (0.15, 0.15, s[2] * 2),
          (0.30, 0.20, s[4] * 2), (0.55, 0.15, s[2] * 2),
          (0.70, 0.15, s[4] * 2), (0.85, 0.30, t.topNote),
        ];
      case GameType.treasure: // 모험 승리 테마
        return [
          (0.0, 0.18, s[0] * 2), (0.18, 0.18, s[2] * 2),
          (0.36, 0.18, s[4] * 2), (0.60, 0.15, s[3] * 2),
          (0.75, 0.15, s[5] * 2), (0.90, 0.30, t.topNote),
        ];
      case GameType.catchme: // 극적 캐치 성공
        return [
          (0.0, 0.08, s[0] * 2), (0.08, 0.08, s[2] * 2),
          (0.16, 0.08, s[4] * 2), (0.28, 0.08, s[0] * 2),
          (0.36, 0.08, s[4] * 2), (0.44, 0.25, t.topNote),
        ];
    }
  }

  // ─── Sound Generators ───────────────────────────────

  Uint8List _genStart(GameType g, _ThemeData t) {
    final dur = _startDuration(g);
    final n = (_sampleRate * dur).toInt();
    final samples = List<int>.filled(n, 0);
    final notes = _startNotes(g, t);

    for (int i = 0; i < n; i++) {
      final time = i / _sampleRate;
      double v = 0;

      for (final (start, freq) in notes) {
        if (time >= start) {
          v += _toneFor(t.tone, time - start, freq, 0.5, t.startDecay);
        }
      }

      final lastStart = notes.last.$1;
      if (time >= lastStart) {
        final st = time - lastStart;
        v += sin(2 * pi * t.rootLow * st) * exp(-st * 4) * 0.25;
        v += sin(2 * pi * t.topNote * st) * exp(-st * 10) * 0.15;
      }

      samples[i] = (v * 28000).toInt().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  Uint8List _genBall(GameType g, _ThemeData t, int idx) {
    final freq = t.scale[idx.clamp(0, 6)];
    final dur = t.ballDecay > 18 ? 0.20 : 0.25;
    final n = (_sampleRate * dur).toInt();
    final samples = List<int>.filled(n, 0);

    for (int i = 0; i < n; i++) {
      final time = i / _sampleRate;
      final bend = t.pitchBend;
      final bendFreq = freq * (1 + bend - bend * (1 - exp(-time * 50)));
      final env = exp(-time * t.ballDecay);
      final v = _rawTone(t.tone, time, bendFreq, env);
      samples[i] = (v * 30000).toInt().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  Uint8List _genComplete(GameType g, _ThemeData t) {
    const dur = 2.0;
    final n = (_sampleRate * dur).toInt();
    final samples = List<int>.filled(n, 0);
    final melody = _completeMelody(g, t);

    final kickStart = melody.last.$1 + melody.last.$2 + 0.15;

    for (int i = 0; i < n; i++) {
      final time = i / _sampleRate;
      double v = 0;

      for (final (start, len, freq) in melody) {
        if (time >= start && time < start + len + 0.35) {
          final nt = time - start;
          v += _toneFor(t.tone, nt, freq, 0.45, 6.0);
          v += sin(2 * pi * freq * 0.5 * nt) * exp(-nt * 5) * 0.15;
        }
      }

      for (int k = 0; k < 4; k++) {
        final ks = kickStart + k * 0.12;
        if (time >= ks) {
          v += _impactFor(t.tone, time - ks, t.rootLow, 0.35);
        }
      }

      if (time >= 1.4) {
        final ct = time - 1.4;
        final padEnv = exp(-ct * 2.0) * 0.15;
        for (final f in [t.scale[0] * 2, t.scale[2] * 2, t.scale[4] * 2]) {
          v += sin(2 * pi * f * ct) * padEnv;
          v += sin(2 * pi * f * 0.5 * ct) * padEnv * 0.3;
        }
      }

      samples[i] = (v * 26000).toInt().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  Uint8List _genSpecial(GameType g, _ThemeData t) {
    const dur = 0.6;
    final n = (_sampleRate * dur).toInt();
    final samples = List<int>.filled(n, 0);
    final s = t.scale;

    final arp = [
      (0.0, s[4]),
      (0.06, s[6]),
      (0.12, s[2] * 2),
      (0.18, s[4] * 2),
    ];

    for (int i = 0; i < n; i++) {
      final time = i / _sampleRate;
      double v = 0;

      for (final (start, freq) in arp) {
        if (time >= start) {
          v += _toneFor(t.tone, time - start, freq, 0.45, 10.0);
        }
      }

      if (time >= 0.24) {
        final st = time - 0.24;
        final env = exp(-st * 6) * 0.4;
        v += sin(2 * pi * t.rootLow * st) * env;
        v += sin(2 * pi * t.rootLow * 1.5 * st) * env * 0.5;
      }

      samples[i] = (v * 30000).toInt().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  Uint8List _genHit(GameType g, _ThemeData t) {
    const dur = 1.4;
    final n = (_sampleRate * dur).toInt();
    final samples = List<int>.filled(n, 0);
    final s = t.scale;

    final fanfare = [
      (0.0, 0.08, s[0]),
      (0.07, 0.08, s[2]),
      (0.14, 0.08, s[4]),
      (0.21, 0.08, s[0] * 2),
      (0.28, 0.08, s[2] * 2),
      (0.35, 0.15, s[4] * 2),
    ];

    for (int i = 0; i < n; i++) {
      final time = i / _sampleRate;
      double v = 0;

      for (final (start, len, freq) in fanfare) {
        if (time >= start && time < start + len + 0.5) {
          v += _toneFor(t.tone, time - start, freq, 0.4, 5.0);
        }
      }

      if (time >= 0.45) {
        final ct = time - 0.45;
        final env = exp(-ct * 3.0) * 0.3;
        v += sin(2 * pi * t.rootLow * 0.5 * ct) * env;
        v += sin(2 * pi * t.rootLow * ct) * env * 0.5;
      }

      for (int c = 0; c < 4; c++) {
        final cs = 0.55 + c * 0.12;
        if (time >= cs) {
          v += _impactFor(t.tone, time - cs, s[0], 0.2);
        }
      }

      if (time >= 0.8) {
        final ct = time - 0.8;
        final env = exp(-ct * 2.0) * 0.12;
        for (final f in [s[0] * 2, s[2] * 2, s[4] * 2]) {
          v += sin(2 * pi * f * ct) * env;
        }
      }

      samples[i] = (v * 28000).toInt().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  Uint8List _genMiss(GameType g, _ThemeData t) {
    const dur = 0.5;
    final n = (_sampleRate * dur).toInt();
    final samples = List<int>.filled(n, 0);
    final baseFreq = t.scale[4] * 2;

    for (int i = 0; i < n; i++) {
      final time = i / _sampleRate;
      final freq = baseFreq * exp(-time * 4);
      final env = exp(-time * 4);
      final v = _rawTone(t.tone, time, freq, env * 0.6) +
          sin(2 * pi * freq * 0.5 * time) * env * 0.35;
      samples[i] = (v * 28000).toInt().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  // ─── Bounce: ball collision pop ─────────────────────

  Uint8List _genBounce(GameType g, _ThemeData t) {
    const dur = 0.1;
    final n = (_sampleRate * dur).toInt();
    final samples = List<int>.filled(n, 0);
    final freq = t.scale[3] * 2;

    for (int i = 0; i < n; i++) {
      final time = i / _sampleRate;
      final env = exp(-time * 60);
      double v = sin(2 * pi * 2500 * time) * exp(-time * 200) * 0.4;
      v += _rawTone(t.tone, time, freq, env * 0.6);
      v += sin(2 * pi * freq * 0.5 * time) * env * 0.2;
      samples[i] = (v * 28000).toInt().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  // ─── Whoosh: upward launch sweep ──────────────────

  Uint8List _genWhoosh(GameType g, _ThemeData t) {
    const dur = 0.3;
    final n = (_sampleRate * dur).toInt();
    final samples = List<int>.filled(n, 0);

    for (int i = 0; i < n; i++) {
      final time = i / _sampleRate;
      final progress = time / dur;
      final freq =
          t.rootLow * 2 + (t.topNote - t.rootLow * 2) * progress * progress;
      final env = sin(pi * progress) * 0.5;
      double v = sin(2 * pi * freq * time) * env;
      v += sin(2 * pi * freq * 1.003 * time) * env * 0.5;
      v += sin(2 * pi * freq * 2.01 * time) * env * 0.2;
      v += sin(2 * pi * freq * 0.498 * time) * env * 0.3;
      samples[i] = (v * 20000).toInt().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  // ─── Mixing: continuous tumble loop ───────────────

  Uint8List _genMixing(GameType g, _ThemeData t) {
    const dur = 2.0;
    final n = (_sampleRate * dur).toInt();
    final samples = List<int>.filled(n, 0);
    final rng = Random(42);

    final clicks = <(double, double)>[];
    double ct = 0.03;
    while (ct < dur - 0.03) {
      final clickFreq = t.scale[rng.nextInt(7)] * (1.0 + rng.nextDouble() * 0.5);
      clicks.add((ct, clickFreq));
      ct += 0.03 + rng.nextDouble() * 0.06;
    }

    for (int i = 0; i < n; i++) {
      final time = i / _sampleRate;
      double v = 0;

      double fade = 1.0;
      if (time < 0.05) fade = time / 0.05;
      if (time > dur - 0.05) fade = (dur - time) / 0.05;

      v += sin(2 * pi * t.rootLow * time) * 0.12;
      v += sin(2 * pi * t.rootLow * 1.5 * time) * 0.06;
      v += sin(2 * pi * t.rootLow * 3.17 * time +
              sin(2 * pi * 5 * time) * 2) *
          0.08;

      for (final (clickTime, clickFreq) in clicks) {
        if (time >= clickTime && time < clickTime + 0.025) {
          final lt = time - clickTime;
          v += sin(2 * pi * clickFreq * lt) * exp(-lt * 100) * 0.25;
          v += sin(2 * pi * clickFreq * 2 * lt) * exp(-lt * 120) * 0.1;
        }
      }

      samples[i] = (v * fade * 22000).toInt().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  // ─── WAV Builder ─────────────────────────────────────

  Uint8List _buildWav(List<int> samples) {
    final dataSize = samples.length * 2;
    final buffer = ByteData(44 + dataSize);

    _writeAscii(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    _writeAscii(buffer, 8, 'WAVE');

    _writeAscii(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, _sampleRate, Endian.little);
    buffer.setUint32(28, _sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);

    _writeAscii(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return buffer.buffer.asUint8List();
  }

  void _writeAscii(ByteData buffer, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      buffer.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
