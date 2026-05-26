import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/analysis_service.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/app_logger.dart';

/// Voice summary button with in-app audio playback
class VoiceSummaryButton extends StatefulWidget {
  const VoiceSummaryButton({
    super.key,
    required this.analysisId,
  });

  final int analysisId;

  @override
  State<VoiceSummaryButton> createState() => _VoiceSummaryButtonState();
}

enum _VoiceState { idle, generating, downloading, ready, playing, paused, failed }

class _VoiceSummaryButtonState extends State<VoiceSummaryButton> {
  _VoiceState _state = _VoiceState.idle;
  String? _audioUrl;
  File? _localFile;
  AudioPlayer? _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playerReady = false;

  @override
  void initState() {
    super.initState();
    _checkExistingFile();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/voice_${widget.analysisId}.mp3');
  }

  Future<void> _checkExistingFile() async {
    try {
      final file = await _getLocalFile();
      if (file.existsSync() && file.lengthSync() > 0) {
        _localFile = file;
        await _initPlayer();
        // Only set ready AFTER player is fully loaded
        if (mounted && _playerReady) {
          setState(() => _state = _VoiceState.ready);
        }
      }
    } catch (e) {
      AppLogger.w('Failed to check existing voice file: $e');
    }
  }

  Future<void> _initPlayer() async {
    _playerReady = false;
    _player?.dispose();
    final player = AudioPlayer();
    _player = player;

    player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });

    player.playerStateStream.listen((playerState) {
      if (!mounted) return;
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _state = _VoiceState.ready;
          _position = Duration.zero;
        });
        player.seek(Duration.zero);
        player.pause();
      } else if (playerState.playing && _state != _VoiceState.playing) {
        setState(() => _state = _VoiceState.playing);
      } else if (!playerState.playing &&
          _state == _VoiceState.playing &&
          playerState.processingState != ProcessingState.completed) {
        setState(() => _state = _VoiceState.paused);
      }
    });

    if (_localFile != null && _localFile!.existsSync()) {
      try {
        await player.setFilePath(_localFile!.path);
        _playerReady = true;
      } catch (e) {
        AppLogger.e('Failed to load audio file', error: e);
        _playerReady = false;
      }
    }
  }

  Future<void> _requestVoice() async {
    setState(() => _state = _VoiceState.generating);
    VHaptics.light();

    try {
      final result = await AnalysisService.instance.requestAndPollVoiceSummary(
        widget.analysisId,
        onProgress: (status) {
          if (mounted && status.isProcessing) {
            setState(() => _state = _VoiceState.generating);
          }
        },
      );

      if (!mounted) return;

      if (result != null && result.isCompleted && result.audioUrl != null) {
        _audioUrl = result.audioUrl;
        await _downloadAudio();
      } else {
        setState(() => _state = _VoiceState.failed);
      }
    } catch (e) {
      AppLogger.e('Voice request failed', error: e);
      if (mounted) setState(() => _state = _VoiceState.failed);
    }
  }

  Future<void> _downloadAudio() async {
    if (_audioUrl == null) return;
    setState(() => _state = _VoiceState.downloading);

    try {
      final file = await _getLocalFile();
      await Dio().download(_audioUrl!, file.path);
      _localFile = file;
      await _initPlayer();
      if (mounted) {
        setState(() => _state = _playerReady ? _VoiceState.ready : _VoiceState.failed);
      }
    } on DioException catch (e) {
      // Per api.md §6.8: the server caches the original Replicate URL and
      // never regenerates. A 4xx here means the upstream audio file has
      // been garbage-collected — there is no backend "regenerate" path
      // today, so the user is stuck. Log distinctly so we can spot it.
      final code = e.response?.statusCode;
      if (code != null && code >= 400 && code < 500) {
        AppLogger.w('Voice audio URL appears expired (HTTP $code): $_audioUrl');
      } else {
        AppLogger.e('Failed to download voice audio', error: e);
      }
      if (mounted) setState(() => _state = _VoiceState.failed);
    } catch (e) {
      AppLogger.e('Failed to download voice audio', error: e);
      if (mounted) setState(() => _state = _VoiceState.failed);
    }
  }

  Future<void> _play() async {
    final player = _player;
    if (player == null || !_playerReady) {
      // Player not loaded yet, try re-init
      if (_localFile != null && _localFile!.existsSync()) {
        await _initPlayer();
        if (!_playerReady) return;
      } else {
        return;
      }
    }

    VHaptics.light();
    // Set playing state immediately so the icon updates on first tap
    setState(() => _state = _VoiceState.playing);
    try {
      await _player?.play();
    } catch (e) {
      AppLogger.e('Failed to play audio', error: e);
      if (mounted) setState(() => _state = _VoiceState.ready);
    }
  }

  Future<void> _pause() async {
    try {
      await _player?.pause();
    } catch (_) {}
    if (mounted) setState(() => _state = _VoiceState.paused);
  }

  void _onTap() {
    switch (_state) {
      case _VoiceState.idle:
        _requestVoice();
        return;
      case _VoiceState.generating:
      case _VoiceState.downloading:
        return;
      case _VoiceState.ready:
      case _VoiceState.paused:
        _play();
        return;
      case _VoiceState.playing:
        _pause();
        return;
      case _VoiceState.failed:
        _requestVoice();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _state == _VoiceState.playing || _state == _VoiceState.paused;

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive || _state == _VoiceState.ready
              ? VColors.aiGradient
              : null,
          color: _state == _VoiceState.failed
              ? VColors.error.withValues(alpha: 0.1)
              : isActive || _state == _VoiceState.ready
                  ? null
                  : VColors.surfaceCard,
          borderRadius: VRadii.lgRadius,
          border: _state == _VoiceState.idle
              ? Border.all(color: VColors.border(context))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildIcon(),
                VSpace.h3,
                Expanded(child: _buildLabel()),
                if (isActive && _duration.inSeconds > 0)
                  Text(
                    _formatDuration(_position),
                    style: VType.caption.copyWith(color: Colors.white),
                  ),
              ],
            ),
            if (isActive && _duration.inMilliseconds > 0) ...[
              VSpace.v2,
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildIcon() {
    switch (_state) {
      case _VoiceState.idle:
        return Icon(VIcons.ai, size: 20, color: VColors.aiGradientStart);
      case _VoiceState.generating:
      case _VoiceState.downloading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: VColors.aiGradientStart,
          ),
        );
      case _VoiceState.ready:
      case _VoiceState.paused:
        return const Icon(Icons.play_arrow_rounded, size: 22, color: Colors.white);
      case _VoiceState.playing:
        return const Icon(Icons.pause_rounded, size: 22, color: Colors.white);
      case _VoiceState.failed:
        return Icon(VIcons.refresh, size: 20, color: VColors.error);
    }
  }

  Widget _buildLabel() {
    switch (_state) {
      case _VoiceState.idle:
        return Text(
          'enhance.voice_listen'.tr(),
          style: VType.label.copyWith(color: VColors.aiGradientStart),
        );
      case _VoiceState.generating:
        return Text(
          'enhance.voice_generating'.tr(),
          style: VType.label.copyWith(color: VColors.aiGradientStart),
        );
      case _VoiceState.downloading:
        return Text(
          'enhance.voice_loading'.tr(),
          style: VType.label.copyWith(color: VColors.aiGradientStart),
        );
      case _VoiceState.ready:
      case _VoiceState.paused:
        return Text(
          'enhance.voice_listen'.tr(),
          style: VType.label.copyWith(color: Colors.white),
        );
      case _VoiceState.playing:
        return Text(
          'enhance.voice_summary'.tr(),
          style: VType.label.copyWith(color: Colors.white),
        );
      case _VoiceState.failed:
        return Text(
          'enhance.voice_failed'.tr(),
          style: VType.label.copyWith(color: VColors.error),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
    }
  }
}
