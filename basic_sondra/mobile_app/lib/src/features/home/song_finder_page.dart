import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/song_match_result.dart';
import '../../services/song_search_api.dart';
import 'song_finder_controller.dart';

class SongFinderPage extends StatefulWidget {
  const SongFinderPage({super.key});

  @override
  State<SongFinderPage> createState() => _SongFinderPageState();
}

class _SongFinderPageState extends State<SongFinderPage> {
  late final SongFinderController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = SongFinderController(api: SongSearchApi());
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              const _DynamicBackground(),
              SafeArea(
                bottom: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.04),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentTab(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _HomeTab(key: const ValueKey(0), controller: _controller);
      case 1:
        return _SongListTab(
          key: const ValueKey(1),
          controller: _controller,
          title: 'Geçmiş',
          emptyIcon: Icons.history_rounded,
          emptyText: 'Henüz şarkı geçmişi yok.',
          items: _controller.history,
          onDelete: (idx) => _controller.removeHistoryItem(idx),
          onClear: () => _controller.clearHistory(),
          showDateGroups: true,
          showTime: true,
        );
      case 2:
        return _SongListTab(
          key: const ValueKey(2),
          controller: _controller,
          title: 'Kaydedilenler',
          emptyIcon: Icons.favorite_border_rounded,
          emptyText: 'Henüz şarkı kaydetmedin.',
          items: _controller.savedSongs,
          onDelete: (idx) => _controller.removeSavedSong(idx),
          onClear: () => _controller.clearSavedSongs(),
          showDateGroups: false,
          showTime: false,
        );
      case 3:
      default:
        return _SettingsTab(key: const ValueKey(3), controller: _controller);
    }
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: const Color(0xFF2DD4BF).withOpacity(0.2),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(color: Color(0xFF5EEAD4), fontSize: 12, fontWeight: FontWeight.bold);
                }
                return TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.normal);
              }),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 75,
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) {
                HapticFeedback.lightImpact();
                _controller.audioPlayer.pause();
                setState(() => _currentIndex = idx);
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.mic_none_rounded, color: Colors.white.withOpacity(0.6)),
                  selectedIcon: const Icon(Icons.mic_rounded, color: Color(0xFF5EEAD4)),
                  label: 'Ana Sayfa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded, color: Colors.white.withOpacity(0.6)),
                  selectedIcon: const Icon(Icons.history_rounded, color: Color(0xFF5EEAD4)),
                  label: 'Geçmiş',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline_rounded, color: Colors.white.withOpacity(0.6)),
                  selectedIcon: const Icon(Icons.favorite_rounded, color: Color(0xFF5EEAD4)),
                  label: 'Kaydedilenler',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: Colors.white.withOpacity(0.6)),
                  selectedIcon: const Icon(Icons.settings_rounded, color: Color(0xFF5EEAD4)),
                  label: 'Ayarlar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicBackground extends StatefulWidget {
  const _DynamicBackground();

  @override
  State<_DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<_DynamicBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF052E16), const Color(0xFF022C11), _anim.value)!,
                Color.lerp(const Color(0xFF14532D), const Color(0xFF166534), _anim.value)!,
                Color.lerp(const Color(0xFF15803D), const Color(0xFF16A34A), _anim.value)!,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  final SongFinderController controller;
  const _HomeTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool showResult = controller.phase == SongFinderPhase.found ||
        controller.phase == SongFinderPhase.notFound ||
        controller.phase == SongFinderPhase.error;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutExpo,
      switchOutCurve: Curves.easeInExpo,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: showResult
          ? _ResultView(key: const ValueKey('result'), controller: controller)
          : _ListeningView(key: const ValueKey('listening'), controller: controller),
    );
  }
}

class _ListeningView extends StatelessWidget {
  final SongFinderController controller;
  const _ListeningView({super.key, required this.controller});

  String _getStatusText() {
    switch (controller.phase) {
      case SongFinderPhase.idle:
        return 'Unutamadığınız o müziği bulmak için\ndokunun veya cihazınızı sallayın :)';
      case SongFinderPhase.listening:
        return 'Dinleniyor...';
      case SongFinderPhase.searching:
        return 'Analiz Ediliyor...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
           top: 100, left: -60,
           child: Opacity(
             opacity: 0.8,
             child: Container(
               width: 250, height: 250,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: const Color(0xFF4ADE80).withOpacity(0.15),
               ),
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                 child: Container(color: Colors.transparent),
               ),
             ),
           )
        ),
        Positioned(
           bottom: 120, right: -80,
           child: Opacity(
             opacity: 0.8,
             child: Container(
               width: 300, height: 300,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: const Color(0xFF86EFAC).withOpacity(0.1),
               ),
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                 child: Container(color: Colors.transparent),
               ),
             ),
           )
        ),
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.graphic_eq_rounded, color: Color(0xFF86EFAC), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Sondra Music Discovery',
                        style: TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      )
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 4),
              _PulseButton(controller: controller),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _getStatusText(),
                    key: ValueKey(controller.phase),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: controller.phase == SongFinderPhase.idle 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.white,
                      fontSize: controller.phase == SongFinderPhase.idle ? 16 : 28,
                      fontWeight: controller.phase == SongFinderPhase.idle ? FontWeight.w500 : FontWeight.w900,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: (controller.phase == SongFinderPhase.listening || controller.phase == SongFinderPhase.searching) ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !(controller.phase == SongFinderPhase.listening || controller.phase == SongFinderPhase.searching),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: Colors.white.withOpacity(0.05),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      controller.cancelListening();
                    },
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    label: const Text(
                      'İptal Et',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class _AudioVisualizer extends StatefulWidget {
  const _AudioVisualizer();

  @override
  State<_AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<_AudioVisualizer> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(10, (index) {
            double value = math.sin((_anim.value * math.pi * 2) + (index * 0.5));
            double height = 15 + (value.abs() * 25); 
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFF86EFAC),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4ADE80).withOpacity(0.5), blurRadius: 8),
                ]
              ),
            );
          }),
        );
      },
    );
  }
}

class _PulseButton extends StatefulWidget {
  final SongFinderController controller;
  const _PulseButton({required this.controller});

  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isIdle = widget.controller.phase == SongFinderPhase.idle;
    final bool isListening = widget.controller.phase == SongFinderPhase.listening;
    final bool isSearching = widget.controller.phase == SongFinderPhase.searching;

    return GestureDetector(
      onTap: () {
        if (isIdle) {
          HapticFeedback.heavyImpact();
          widget.controller.triggerListening();
        }
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          double pulseScale = isIdle ? 1.0 + (_anim.value * 0.25) : (isListening ? 1.0 + (_anim.value * 0.45) : 1.0);
          double pulseOpacity = isIdle ? 0.3 * (1.0 - _anim.value) : (isListening ? 0.5 * (1.0 - _anim.value) : 0.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ripple
              if (!isSearching)
                Opacity(
                  opacity: pulseOpacity * 0.5,
                  child: Transform.scale(
                    scale: pulseScale * 1.2,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                      ),
                    ),
                  ),
                ),
              // Inner Ripple
              if (!isSearching)
                Opacity(
                  opacity: pulseOpacity,
                  child: Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ),
              // Waveform (if listening)
              if (isListening)
                SizedBox(
                  width: 210,
                  height: 210,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: widget.controller.recordingProgress),
                    duration: const Duration(milliseconds: 150),
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.9)),
                      );
                    },
                  ),
                ),
              // Main Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: isListening ? 180 : 200,
                height: isListening ? 180 : 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isListening ? const Color(0xFF22C55E).withOpacity(0.8) : const Color(0xFF15803D).withOpacity(0.5),
                      blurRadius: isListening ? 50 : 25,
                      spreadRadius: isListening ? 15 : 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Center(
                  child: isSearching
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Icon(
                          Icons.stream_rounded,
                          color: Colors.white,
                          size: isListening ? 80 : 100,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultView extends StatefulWidget {
  final SongFinderController controller;
  const _ResultView({super.key, required this.controller});

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  AudioPlayer get _audioPlayer => widget.controller.audioPlayer;
  StreamSubscription? _playerSub;

  @override
  void initState() {
    super.initState();
    _playerSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      final isCurrentView = widget.controller.currentPreviewId == 'RESULT_VIEW';
      if (!isCurrentView) {
         if (_isPlaying || _isLoadingAudio) {
           setState(() { _isPlaying = false; _isLoadingAudio = false; });
         }
         return;
      }
      setState(() {
        _isPlaying = state.playing;
        _isLoadingAudio = state.processingState == ProcessingState.buffering || state.processingState == ProcessingState.loading;
        if (state.processingState == ProcessingState.completed) _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    super.dispose();
  }

  void _togglePlay() async {
    final previewUrl = widget.controller.latestResult?.previewUrl;
    if (previewUrl == null) return;

    try {
      if (_isPlaying && widget.controller.currentPreviewId == 'RESULT_VIEW') {
        await _audioPlayer.pause();
      } else {
        if (mounted) setState(() { _isLoadingAudio = true; });
        widget.controller.currentPreviewId = 'RESULT_VIEW';
        await _audioPlayer.setUrl(previewUrl);
        await _audioPlayer.play();
      }
    } catch (_) {
      if (mounted) setState(() { _isLoadingAudio = false; _isPlaying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFound = widget.controller.phase == SongFinderPhase.found;
    bool isError = widget.controller.phase == SongFinderPhase.error;

    String title = '';
    String subtitle = '';
    String? coverUrl;
    String? previewUrl;

    if (isFound) {
      title = widget.controller.latestResult?.title ?? 'Bilinmeyen Şarkı';
      subtitle = widget.controller.latestResult?.artist ?? 'Bilinmeyen Sanatçı';
      coverUrl = widget.controller.latestResult?.albumCoverUrl;
      previewUrl = widget.controller.latestResult?.previewUrl;
    } else if (isError) {
      title = 'Bağlantı Hatası';
      subtitle = widget.controller.errorMessage ?? 'Bir sorun oluştu.';
    } else {
      title = 'Şarkı Bulunamadı';
      subtitle = widget.controller.latestResult?.message ?? 'Lütfen tekrar deneyin.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Album cover placeholder or error icon
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 50,
                    offset: const Offset(0, 20),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                     if (coverUrl != null)
                      Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          isFound ? Icons.music_note_rounded : Icons.error_outline_rounded,
                          size: 120,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white54));
                        },
                      )
                     else
                      Icon(
                        isFound ? Icons.music_note_rounded : Icons.error_outline_rounded,
                        size: 120,
                        color: Colors.white.withOpacity(0.9),
                      ),

                ],
              ),
            ),
          ),
          ),
          const SizedBox(height: 50),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (previewUrl != null) ...[
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: _togglePlay,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isPlaying ? const Color(0xFF16A34A).withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _isPlaying ? const Color(0xFF4ADE80) : Colors.white.withOpacity(0.2), width: 1.5),
                    boxShadow: [
                      if (_isPlaying) BoxShadow(color: const Color(0xFF4ADE80).withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoadingAudio)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      else
                        Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _isPlaying ? const Color(0xFF86EFAC) : Colors.white),
                      
                      if (_isPlaying && !_isLoadingAudio) ...[
                        const SizedBox(width: 16),
                        const _AudioVisualizer(),
                      ] else if (!_isLoadingAudio) ...[
                        const SizedBox(width: 12),
                        const Text(
                          'Dinle',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ] else ...[
            const SizedBox(height: 60),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.controller.audioPlayer.pause();
                    widget.controller.resetState();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  label: const Text('Geri', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (isFound) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 10,
                      shadowColor: const Color(0xFF16A34A).withOpacity(0.5),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      bool success = widget.controller.saveCurrentSong();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Şarkı kaydedildi!' : 'Bu şarkı zaten kayıtlı!'),
                          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                    label: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RenderItem {
  final String? header;
  final SongRecognitionHistoryItem? item;
  final int index;
  _RenderItem({this.header, this.item, this.index = -1});
}

class _SongListTab extends StatelessWidget {
  final SongFinderController controller;
  final String title;
  final IconData emptyIcon;
  final String emptyText;
  final List<SongRecognitionHistoryItem> items;
  final void Function(int) onDelete;
  final VoidCallback onClear;
  final bool showDateGroups;
  final bool showTime;

  const _SongListTab({
    super.key,
    required this.controller,
    required this.title,
    required this.emptyIcon,
    required this.emptyText,
    required this.items,
    required this.onDelete,
    required this.onClear,
    this.showDateGroups = false,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<_RenderItem> renderList = [];
    if (showDateGroups) {
      String? lastGroup;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final date = DateTime(item.recognizedAt.year, item.recognizedAt.month, item.recognizedAt.day);
        String group = '';
        if (date == today) {
          group = 'Bugün';
        } else if (date == yesterday) {
          group = 'Dün';
        } else {
          group = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        }
        
        if (group != lastGroup) {
          renderList.add(_RenderItem(header: group));
          lastGroup = group;
        }
        renderList.add(_RenderItem(item: item, index: i));
      }
    } else {
      for (int i = 0; i < items.length; i++) {
        renderList.add(_RenderItem(item: items[i], index: i));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 80, left: 30, right: 30, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
              ),
              if (items.isNotEmpty)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
                  tooltip: 'Tümünü Sil',
                )
            ]
          ),
        ),
        if (items.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 80, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 20),
                  Text(emptyText, style: const TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 120, left: 24, right: 24),
              itemCount: renderList.length,
              itemBuilder: (ctx, idx) {
                final element = renderList[idx];
                
                if (element.header != null) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 24, bottom: 12, left: 10),
                     child: Text(
                       element.header!, 
                       style: const TextStyle(color: Color(0xFF5EEAD4), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                     ),
                   );
                }

                final item = element.item!;
                final originalIndex = element.index;
                final time = '${item.recognizedAt.hour.toString().padLeft(2, '0')}:${item.recognizedAt.minute.toString().padLeft(2, '0')}';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF15803D).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: item.albumCoverUrl != null
                              ? Image.network(
                                  item.albumCoverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, color: Colors.white, size: 30),
                                )
                              : const Icon(Icons.music_note_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.artist,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (item.previewUrl != null) ...[
                        const SizedBox(width: 8),
                         _InlineAudioPlayer(id: item.unqId, url: item.previewUrl!, controller: controller),
                      ],
                      if (showTime) ...[
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              time,
                              style: TextStyle(color: const Color(0xFF5EEAD4).withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => onDelete(originalIndex),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
                              ),
                            )
                          ]
                        )
                      ] else ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => onDelete(originalIndex),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 24),
                          ),
                        )
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final SongFinderController controller;
  const _SettingsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 80, left: 30, right: 30, bottom: 120),
      children: [
        const Text(
          'Ayarlar',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
        ),
        const SizedBox(height: 30),
        _SettingsCard(
          title: 'Mikrofon',
          subtitle: controller.microphoneReady ? 'Erişim İzni Aktif' : 'Erişim İzni Bekleniyor',
          icon: controller.microphoneReady ? Icons.mic_rounded : Icons.mic_off_rounded,
          iconColor: controller.microphoneReady ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          trailing: Switch(
            value: controller.microphoneReady,
            onChanged: (val) {
              controller.requestMicrophoneToggle();
            },
            activeColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Sunucu Bağlantısı',
          subtitle: 'Uç Nokta: ${controller.apiBaseUrl}',
          icon: Icons.cloud_done_rounded,
          iconColor: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Shake Assist (Sallama ile)',
          subtitle: controller.accelerometerArmed || controller.gyroscopeArmed
              ? 'Sensörler şu anda tetikte (Aktif)'
              : 'Sensör yardımı hazır bekliyor',
          icon: Icons.vibration_rounded,
          iconColor: const Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;

  const _SettingsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!
          ],
        ],
      ),
    );
  }
}

class _InlineAudioPlayer extends StatefulWidget {
  final String id;
  final String url;
  final SongFinderController controller;
  const _InlineAudioPlayer({required this.id, required this.url, required this.controller});

  @override
  State<_InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<_InlineAudioPlayer> {
  bool _isPlaying = false;
  bool _isLoading = false;
  StreamSubscription? _playerSub;

  AudioPlayer get _audioPlayer => widget.controller.audioPlayer;

  @override
  void initState() {
    super.initState();
    _playerSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      final isCurrentId = widget.controller.currentPreviewId == widget.id;
      if (!isCurrentId) {
         if (_isPlaying || _isLoading) {
           setState(() { _isPlaying = false; _isLoading = false; });
         }
         return;
      }
      setState(() {
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.buffering || state.processingState == ProcessingState.loading;
        if (state.processingState == ProcessingState.completed) _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    super.dispose();
  }

  void _togglePlay() async {
    try {
      if (_isPlaying && widget.controller.currentPreviewId == widget.id) {
        await _audioPlayer.pause();
      } else {
        if (mounted) setState(() => _isLoading = true);
        widget.controller.currentPreviewId = widget.id;
        await _audioPlayer.setUrl(widget.url);
        await _audioPlayer.play();
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _isPlaying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isPlaying ? const Color(0xFF16A34A).withOpacity(0.2) : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: _isPlaying ? const Color(0xFF4ADE80) : Colors.white.withOpacity(0.1)),
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _isPlaying ? const Color(0xFF4ADE80) : Colors.white, size: 24),
      ),
    );
  }
}
