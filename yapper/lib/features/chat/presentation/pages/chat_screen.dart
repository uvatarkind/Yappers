import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yapper/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:yapper/features/chat/presentation/bloc/chat/chat_event.dart';
import 'package:yapper/features/chat/presentation/bloc/chat/chat_state.dart';
import 'package:yapper/core/widgets/loading_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:yapper/features/chat/domain/entities/message_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String title;
  final String receiverProfileImageUrl;
  final bool isReceiverOnline;
  final DateTime? lastSeen;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.title,
    required this.receiverProfileImageUrl,
    this.isReceiverOnline = false,
    this.lastSeen,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  bool _showEmojiPicker = false;
  bool _isRecording = false;
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  Timer? _recTimer;
  DateTime? _recStart;
  File? _pendingVoiceFile;
  AudioPlayer? _previewPlayer;
  Duration _previewDuration = Duration.zero;
  Duration _previewPosition = Duration.zero;
  bool _isPreviewPlaying = false;
  bool _previewHasPlayed = false;
  late final AnimationController _recordAnimationController;
  late final Animation<double> _recordPulseAnimation;
  static const List<String> _emojiList = [
    '😀',
    '😂',
    '😍',
    '👍',
    '🙏',
    '🎉',
    '😢',
    '😎',
    '🔥',
    '😁',
    '😭',
    '🤔',
    '😅',
    '😉',
    '😄',
    '🤗',
    '😇',
    '🤩',
  ];

  String? get _currentUserId => context.read<ChatBloc>().currentUserId;

  @override
  void initState() {
    super.initState();
    _recordAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _recordPulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _recordAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    context.read<ChatBloc>().add(LoadMessages(widget.chatId));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _recorder.dispose();
    _recTimer?.cancel();
    _previewPlayer?.dispose();
    _recordAnimationController.dispose();
    super.dispose();
  }

  void _send() {
    if (_pendingVoiceFile != null) {
      _sendPendingVoice();
      return;
    }
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(
          SendTextMessage(text, receiverId: widget.receiverId),
        );
    _ctrl.clear();
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }
      final picked = result.files.single;
      File? file;
      if (picked.path != null) {
        file = File(picked.path!);
      } else if (picked.bytes != null) {
        final dir = await getTemporaryDirectory();
        final fname = picked.name.isNotEmpty
            ? picked.name
            : 'file_${DateTime.now().millisecondsSinceEpoch}';
        final tempPath = '${dir.path}/$fname';
        file = await File(tempPath).writeAsBytes(picked.bytes!);
      }
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read selected file')),
        );
        return;
      }
      final ext = file.path.split('.').last.toLowerCase();
      final isImage =
          ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'bmp'].contains(ext);
      final type = isImage ? MessageType.image : MessageType.file;
      context.read<ChatBloc>().add(
            SendFileMessage(
                file: file, type: type, receiverId: widget.receiverId),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sending ${isImage ? 'image' : 'file'}...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attach failed: $e')),
      );
    }
  }

  Future<void> _preparePreviewPlayer(File file) async {
    await _previewPlayer?.stop();
    await _previewPlayer?.dispose();

    final player = AudioPlayer();
    _previewDuration = Duration.zero;
    _previewPosition = Duration.zero;
    _isPreviewPlaying = false;
    _previewHasPlayed = false;

    player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _previewDuration = d);
    });
    player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _previewPosition = p);
    });
    player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      if (state == PlayerState.completed) {
        setState(() {
          _isPreviewPlaying = false;
          _previewPosition = _previewDuration;
        });
      } else {
        setState(() => _isPreviewPlaying = state == PlayerState.playing);
      }
    });

    try {
      await player.setSource(DeviceFileSource(file.path));
    } catch (e) {
      // ignore: avoid_print
      print('Audio preview setup failed: $e');
    }

    if (!mounted) {
      await player.dispose();
      return;
    }

    setState(() {
      _previewPlayer = player;
    });
  }

  Future<void> _togglePreviewPlayback() async {
    final player = _previewPlayer;
    final file = _pendingVoiceFile;
    if (player == null || file == null) return;

    if (_isPreviewPlaying) {
      await player.pause();
      return;
    }

    if (_previewHasPlayed) {
      if (_previewDuration > Duration.zero &&
          _previewPosition >= _previewDuration) {
        await player.seek(Duration.zero);
      }
      await player.resume();
    } else {
      await player.play(DeviceFileSource(file.path));
      _previewHasPlayed = true;
    }
  }

  Future<void> _clearPendingVoice({bool deleteFile = true}) async {
    final file = _pendingVoiceFile;
    try {
      await _previewPlayer?.stop();
      await _previewPlayer?.dispose();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _previewPlayer = null;
      _pendingVoiceFile = null;
      _previewDuration = Duration.zero;
      _previewPosition = Duration.zero;
      _isPreviewPlaying = false;
      _previewHasPlayed = false;
    });
    if (deleteFile && file != null && await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  Future<void> _sendPendingVoice() async {
    final file = _pendingVoiceFile;
    if (file == null) return;
    context
        .read<ChatBloc>()
        .add(SendVoiceMessage(audioFile: file, receiverId: widget.receiverId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending voice message...')),
    );
    await _clearPendingVoice(deleteFile: false);
  }

  Widget _buildRecordingBar(BuildContext context) {
    final accent = Colors.purpleAccent;
    final elapsed = _recStart != null
        ? _fmtElapsed(DateTime.now().difference(_recStart!))
        : '00:00';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.15), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.35)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScaleTransition(
                scale: _recordPulseAnimation,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFCE93D8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording…',
                      style: TextStyle(
                        color: accent.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      elapsed,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRecordingWaveform(accent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _toggleRecord,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingWaveform(MaterialAccentColor accent) {
    return AnimatedBuilder(
      animation: _recordAnimationController,
      builder: (context, _) {
        final value = _recordAnimationController.value;
        return SizedBox(
          height: 40,
          width: 88,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(9, (index) {
              final progress = (value + index * 0.12) % 1.0;
              final barHeight =
                  12 + (math.sin(progress * math.pi * 2).abs() * 24);
              return Container(
                width: 6,
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      accent.shade200,
                      accent.shade400,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildPendingVoicePreview(BuildContext context) {
    final accent = Colors.purpleAccent;
    final sliderMax = _previewDuration.inMilliseconds > 0
        ? _previewDuration.inMilliseconds.toDouble()
        : 1.0;
    final sliderValue =
        _previewPosition.inMilliseconds.clamp(0, sliderMax.toInt()).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, accent.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice note preview',
            style: TextStyle(
              color: accent.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: _togglePreviewPlayback,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accent, accent.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPreviewPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accent,
                        inactiveTrackColor: accent.withOpacity(0.3),
                        thumbColor: accent,
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        min: 0,
                        max: sliderMax,
                        value: sliderValue,
                        onChanged: _previewPlayer == null
                            ? null
                            : (v) async {
                                final player = _previewPlayer;
                                if (player == null) return;
                                final newPos =
                                    Duration(milliseconds: v.toInt());
                                await player.seek(newPos);
                                if (!mounted) return;
                                setState(() => _previewPosition = newPos);
                              },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmtElapsed(_previewPosition),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _previewDuration == Duration.zero
                              ? '--:--'
                              : _fmtElapsed(_previewDuration),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _clearPendingVoice(),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Discard'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _sendPendingVoice,
                icon: const Icon(Icons.send),
                label: const Text('Send voice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      _recordAnimationController.stop();
      _recordAnimationController.reset();
      _recTimer?.cancel();
      _recStart = null;
      setState(() => _isRecording = false);
      final finalPath = path ?? _currentRecordingPath;
      _currentRecordingPath = null;
      if (finalPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording failed to save')),
        );
        return;
      }
      final file = File(finalPath);
      if (!await file.exists() || await file.length() == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording too short')),
        );
        await _clearPendingVoice(deleteFile: true);
        return;
      }
      await _preparePreviewPlayer(file);
      if (!mounted) return;
      setState(() {
        _pendingVoiceFile = file;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Voice note ready. Preview before sending.')),
      );
    } else {
      if (_pendingVoiceFile != null) {
        await _clearPendingVoice();
      }
      if (!await _recorder.hasPermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
      _currentRecordingPath = filePath;
      _recStart = DateTime.now();
      _recTimer?.cancel();
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      _recordAnimationController.repeat(reverse: true);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _recordAnimationController.stop();
      _recordAnimationController.reset();
      _recTimer?.cancel();
      _recStart = null;
      setState(() => _isRecording = false);
      if (_currentRecordingPath != null) {
        final f = File(_currentRecordingPath!);
        if (await f.exists()) {
          await f.delete();
        }
        _currentRecordingPath = null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording cancelled')),
      );
      return;
    }

    if (_pendingVoiceFile != null) {
      await _clearPendingVoice();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice note discarded')),
      );
    }
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'last seen a long time ago';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inDays > 0) return 'last seen ${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return 'last seen ${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return 'last seen ${diff.inMinutes} minute(s) ago';
    return 'last seen just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        flexibleSpace: SafeArea(
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(width: 2),
              CircleAvatar(
                backgroundImage: widget.receiverProfileImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(widget.receiverProfileImageUrl)
                    : null,
                maxRadius: 20,
                child: widget.receiverProfileImageUrl.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isReceiverOnline
                          ? 'Online'
                          : _formatLastSeen(widget.lastSeen),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔹 Chat Messages Area with Background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/chat_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const YapperLoadingWidget();
                  }
                  if (state is ChatError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is ChatLoaded) {
                    final messages = state.messages;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      // Add cacheExtent to improve scrolling performance
                      cacheExtent: 1000,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final m = messages[index];
                        final bool isMe = m.senderId == _currentUserId;

                        final bubble = _MessageBubble(
                          isMe: isMe,
                          messageType: m.type,
                          content: m.content,
                        );

                        return Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 8.0,
                                  bottom: 2,
                                ),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundImage: CachedNetworkImageProvider(
                                    widget.receiverProfileImageUrl,
                                  ),
                                ),
                              ),
                            Flexible(child: bubble),
                          ],
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // 🔹 Message Input + Emoji Picker + Attachments + Voice
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (_isRecording) _buildRecordingBar(context),
                  if (!_isRecording && _pendingVoiceFile != null)
                    _buildPendingVoicePreview(context),
                  Row(
                    children: [
                      // 📎 File Attachment
                      IconButton(
                        onPressed: (_isRecording || _pendingVoiceFile != null)
                            ? null
                            : _pickAndSendFile,
                        icon: Icon(
                          Icons.attach_file,
                          color: (_isRecording || _pendingVoiceFile != null)
                              ? Colors.black26
                              : Colors.black54,
                        ),
                      ),

                      // 😀 Emoji Picker Toggle
                      IconButton(
                        onPressed: (_isRecording || _pendingVoiceFile != null)
                            ? null
                            : () {
                                setState(() {
                                  _showEmojiPicker = !_showEmojiPicker;
                                });
                              },
                        icon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: (_isRecording || _pendingVoiceFile != null)
                              ? Colors.black26
                              : (_showEmojiPicker
                                  ? Colors.purpleAccent
                                  : Colors.black54),
                        ),
                      ),

                      // ✏️ Message Input Field
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          enabled: !_isRecording && _pendingVoiceFile == null,
                          decoration: InputDecoration(
                            hintText: _pendingVoiceFile != null
                                ? 'Voice note ready...'
                                : 'Message...',
                            filled: true,
                            fillColor: _pendingVoiceFile != null
                                ? Colors.grey[100]
                                : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),

                      // 🎙️ Voice Recording
                      IconButton(
                        onPressed:
                            _pendingVoiceFile != null ? null : _toggleRecord,
                        icon: Icon(
                          _isRecording ? Icons.stop_circle : Icons.mic,
                          color: _isRecording
                              ? Colors.redAccent
                              : (_pendingVoiceFile != null
                                  ? Colors.black26
                                  : Colors.black54),
                        ),
                      ),

                      // 📤 Send
                      IconButton(
                        onPressed: _isRecording ? null : _send,
                        icon: Icon(
                          Icons.send,
                          color: _pendingVoiceFile != null
                              ? Colors.purpleAccent
                              : Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  // 😊 Emoji Picker - Optimized with ListView.builder
                  if (_showEmojiPicker)
                    SizedBox(
                      height: 250,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                        itemCount: _emojiList.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final e = _emojiList[index];
                          return GestureDetector(
                            onTap: () {
                              final newText = _ctrl.text + e;
                              _ctrl.text = newText;
                              _ctrl.selection = TextSelection.fromPosition(
                                TextPosition(offset: newText.length),
                              );
                            },
                            child: Center(
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final MessageType messageType;
  final String content; // text or URL depending on type

  const _MessageBubble({
    required this.isMe,
    required this.messageType,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    Widget child;
    EdgeInsets padding =
        const EdgeInsets.symmetric(vertical: 10, horizontal: 14);
    Color? bg = isMe
        ? Colors.purpleAccent.withOpacity(0.95)
        : Colors.white.withOpacity(0.95);

    switch (messageType) {
      case MessageType.text:
        child = Text(
          content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.3,
          ),
        );
        break;
      case MessageType.image:
        // Image bubble: show image with rounded corners, tap to preview
        padding = const EdgeInsets.all(4);
        bg = Colors.transparent;
        child = _ImageMessage(url: content, isMe: isMe, maxWidth: maxWidth);
        break;
      case MessageType.file:
        child = _FileMessage(url: content, isMe: isMe);
        break;
      case MessageType.audio:
        child = _VoiceMessage(url: content, isMe: isMe);
        break;
    }

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: EdgeInsets.only(
        top: 6,
        bottom: 6,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ImageMessage extends StatelessWidget {
  final String url;
  final bool isMe;
  final double maxWidth;

  const _ImageMessage({
    required this.url,
    required this.isMe,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );
    return ClipRRect(
      borderRadius: radius,
      child: GestureDetector(
        onTap: () => _showFullImage(context, url),
        child: CachedNetworkImage(
          imageUrl: url,
          width: maxWidth,
          fit: BoxFit.cover,
          placeholder: (c, s) => Container(
            height: 100,
            color: Colors.black12,
          ),
          errorWidget: (c, s, e) => Container(
            height: 100,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _FileMessage extends StatelessWidget {
  final String url;
  final bool isMe;
  const _FileMessage({required this.url, required this.isMe});

  String _fileName(String u) {
    try {
      final segs = Uri.parse(u).pathSegments;
      if (segs.isNotEmpty) return Uri.decodeComponent(segs.last);
      return 'attachment';
    } catch (_) {
      return 'attachment';
    }
  }

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (lower.endsWith('.doc') || lower.endsWith('.docx'))
      return Icons.description;
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx'))
      return Icons.table_chart;
    if (lower.endsWith('.zip') || lower.endsWith('.rar')) return Icons.archive;
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) return Icons.image;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final name = _fileName(url);
    final icon = _iconFor(name);
    final textColor = isMe ? Colors.white : Colors.black87;
    return InkWell(
      onTap: () => launchUrlString(url, mode: LaunchMode.externalApplication),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isMe ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: textColor),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tap to open',
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _VoiceMessage extends StatefulWidget {
  final String url;
  final bool isMe;
  const _VoiceMessage({required this.url, required this.isMe});

  @override
  State<_VoiceMessage> createState() => _VoiceMessageState();
}

class _VoiceMessageState extends State<_VoiceMessage> {
  late final AudioPlayer _player;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _dur = d);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _pos = p);
    });
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isMe ? Colors.white : Colors.black87;
    final double max =
        _dur.inMilliseconds.toDouble().clamp(0.0, double.infinity).toDouble();
    final double value =
        _pos.inMilliseconds.toDouble().clamp(0.0, max).toDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _toggle,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white24 : Colors.black12,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: textColor,
            ),
          ),
        ),
        SizedBox(
          width: 110,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              min: 0,
              max: max > 0 ? max : 1,
              value: value > 0 ? value : 0,
              onChanged: (v) async {
                final d = Duration(milliseconds: v.toInt());
                await _player.seek(d);
              },
            ),
          ),
        ),
        Text(
          '${_fmt(_pos)}',
          style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 12),
        )
      ],
    );
  }
}
