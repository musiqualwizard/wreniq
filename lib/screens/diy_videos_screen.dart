import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/diy_video.dart';
import '../services/diy_video_service.dart';
import '../theme/app_theme.dart';

class DiyVideosScreen extends StatefulWidget {
  final String year;
  final String make;
  final String model;
  final String partName;
  final String difficulty;
  final List<String> repairSteps;

  const DiyVideosScreen({
    super.key,
    required this.year,
    required this.make,
    required this.model,
    required this.partName,
    required this.difficulty,
    this.repairSteps = const [],
  });

  @override
  State<DiyVideosScreen> createState() => _DiyVideosScreenState();
}

class _DiyVideosScreenState extends State<DiyVideosScreen> {
  static const _teal = Color(0xFF00D4AA);

  late List<DiyVideo> _videos;
  final Set<String>   _saved       = {};
  bool                _repairMode  = false;
  final Set<int>      _doneSteps   = {};

  @override
  void initState() {
    super.initState();
    _videos = DiyVideoService.forScan(
      year:       widget.year,
      make:       widget.make,
      model:      widget.model,
      partName:   widget.partName,
      difficulty: widget.difficulty,
    );
  }

  // ── URL launcher ────────────────────────────────────────────────────────────

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open YouTube. Check your internet connection.')),
        );
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DIY VIDEOS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Watch-while-repairing mode toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => setState(() {
                _repairMode = !_repairMode;
                if (!_repairMode) _doneSteps.clear();
              }),
              icon: Icon(
                _repairMode ? Icons.build : Icons.build_outlined,
                size: 16,
                color: _repairMode ? _teal : AppTheme.chromeAccent,
              ),
              label: Text(
                _repairMode ? 'EXIT MODE' : 'REPAIR MODE',
                style: TextStyle(
                  color: _repairMode ? _teal : AppTheme.chromeAccent,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _repairMode ? _buildRepairMode() : _buildBrowseMode(),
    );
  }

  // ── Browse Mode ─────────────────────────────────────────────────────────────

  Widget _buildBrowseMode() {
    final vehicle = '${widget.year} ${widget.make} ${widget.model}';
    final searchUrl = DiyVideoService.buildSearchUrl(
      year:     widget.year,
      make:     widget.make,
      model:    widget.model,
      partName: widget.partName,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Context header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.electricBlue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.ondemand_video_outlined,
                      color: AppTheme.electricBlue, size: 16),
                  const SizedBox(width: 8),
                  const Text('DIY VIDEO HUB',
                      style: TextStyle(
                          color: AppTheme.electricBlue,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.partName} — $vehicle',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Smart search links open real YouTube results for your exact vehicle and part.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Repair mode banner
        GestureDetector(
          onTap: () => setState(() => _repairMode = true),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _teal.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_rounded, color: _teal, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Watch While Repairing',
                          style: TextStyle(
                              color: _teal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Step checklist + video side by side',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: _teal, size: 14),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        const _SectionLabel('Featured Videos'),
        const SizedBox(height: 12),

        // Video cards
        ..._videos.map((v) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _VideoCard(
            video:   v,
            isSaved: _saved.contains(v.id),
            onWatch: () => _launch(v.videoUrl),
            onOpen:  () => _launch(v.videoUrl),
            onSave:  () => setState(() {
              if (_saved.contains(v.id)) {
                _saved.remove(v.id);
              } else {
                _saved.add(v.id);
              }
            }),
          ),
        )),

        const SizedBox(height: 8),

        // Search YouTube button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _launch(searchUrl),
            icon: const Icon(Icons.youtube_searched_for, color: AppTheme.electricBlue),
            label: const Text(
              'SEARCH YOUTUBE',
              style: TextStyle(
                  color: AppTheme.electricBlue,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppTheme.electricBlue.withValues(alpha: 0.4), width: 1.2),
              shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildSafetyNote(),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Repair Mode ─────────────────────────────────────────────────────────────

  Widget _buildRepairMode() {
    final steps = widget.repairSteps;

    return Column(
      children: [
        // Mode header banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: _teal.withValues(alpha: 0.12),
          child: Row(
            children: [
              const Icon(Icons.build_rounded, color: _teal, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'WATCH WHILE REPAIRING',
                  style: TextStyle(
                      color: _teal,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (steps.isNotEmpty)
                Text(
                  '${_doneSteps.length}/${steps.length} steps',
                  style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step checklist (left, 40% width)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.42,
                child: steps.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No repair steps available for this part.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _buildStepChecklist(steps),
              ),
              Container(width: 1, color: const Color(0xFF1E1E2E)),
              // Video list (right, 60% width)
              Expanded(child: _buildRepairVideoList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepChecklist(List<String> steps) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: steps.length,
      itemBuilder: (_, i) {
        final done = _doneSteps.contains(i);
        return GestureDetector(
          onTap: () => setState(() {
            if (done) { _doneSteps.remove(i); } else { _doneSteps.add(i); }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: done
                  ? _teal.withValues(alpha: 0.12)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: done
                      ? _teal.withValues(alpha: 0.4)
                      : AppTheme.chromeAccent.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? _teal : AppTheme.chromeAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${i + 1}. ${steps[i]}',
                    style: TextStyle(
                      color: done ? AppTheme.chromeAccent : AppTheme.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepairVideoList() {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _videos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final v = _videos[i];
        return _CompactVideoCard(
          video:  v,
          onTap:  () => _launch(v.videoUrl),
        );
      },
    );
  }

  // ── Safety note ─────────────────────────────────────────────────────────────

  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.warning, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Always verify repairs using multiple sources and follow proper safety procedures. '
              'Wear PPE, use rated jack stands, and consult a professional for high-risk systems.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Video Card ────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final DiyVideo       video;
  final bool           isSaved;
  final VoidCallback   onWatch;
  final VoidCallback   onOpen;
  final VoidCallback   onSave;

  const _VideoCard({
    required this.video,
    required this.isSaved,
    required this.onWatch,
    required this.onOpen,
    required this.onSave,
  });

  Color get _diffColor {
    return switch (video.difficulty) {
      'Beginner'     => const Color(0xFF00E676),
      'Intermediate' => const Color(0xFF00B4FF),
      _              => const Color(0xFFFF9500),
    };
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9C6FFF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 120,
              width: double.infinity,
              color: AppTheme.surface,
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.play_circle_outline,
                        color: AppTheme.electricBlue, size: 52),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _diffColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        video.difficulty,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        video.duration,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Title + channel
          Text(
            video.title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppTheme.chromeAccent, size: 13),
              const SizedBox(width: 4),
              Text(video.channelName,
                  style: const TextStyle(color: AppTheme.chromeAccent, fontSize: 12)),
              const Spacer(),
              if (video.beginnerFriendly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                  ),
                  child: const Text('Beginner friendly',
                      style: TextStyle(color: Color(0xFF00E676), fontSize: 10)),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: onWatch,
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Watch Video', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricBlue,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('YouTube', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.chromeAccent,
                    side: BorderSide(
                        color: AppTheme.chromeAccent.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onSave,
                tooltip: isSaved ? 'Saved' : 'Save video',
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? purple : AppTheme.chromeAccent,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Compact video card (repair mode) ─────────────────────────────────────────

class _CompactVideoCard extends StatelessWidget {
  final DiyVideo     video;
  final VoidCallback onTap;

  const _CompactVideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.electricBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle_outline,
                  color: AppTheme.electricBlue, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(video.channelName,
                      style: const TextStyle(
                          color: AppTheme.chromeAccent, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: AppTheme.chromeAccent, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: AppTheme.chromeAccent,
      fontSize: 11,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
    ),
  );
}
