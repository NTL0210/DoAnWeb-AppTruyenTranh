import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChapterReaderScreen extends StatefulWidget {
  final String chapterApiUrl; // e.g. https://sv1.otruyencdn.com/v1/api/chapter/{id}
  final String? title;
  final List<Map<String, dynamic>>? chapters; // optional: list from details
  final int? initialIndex; // index in chapters
  const ChapterReaderScreen({
    super.key,
    required this.chapterApiUrl,
    this.title,
    this.chapters,
    this.initialIndex,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  bool _loading = true;
  String? _error;
  String _cdn = '';
  String _chapterPath = '';
  List<Map<String, dynamic>> _images = [];
  bool _showControls = false;
  late String _currentApiUrl;
  late int _currentIndex;
  String _currentTitle = '';

  @override
  void initState() {
    super.initState();
    _currentApiUrl = widget.chapterApiUrl;
    _currentIndex = widget.initialIndex ?? 0;
    _currentTitle = widget.title ?? '';
    _fetchChapter();
  }

  Future<void> _fetchChapter() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(_currentApiUrl);
      final resp = await http.get(uri, headers: {'Accept': 'application/json'});
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      final Map<String, dynamic> body = json.decode(resp.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Missing data');
      final item = data['item'] as Map<String, dynamic>?;
      if (item == null) throw Exception('Missing item');
      final List<dynamic> images = (item['chapter_image'] as List<dynamic>?) ?? const [];
      setState(() {
        _cdn = (data['domain_cdn'] ?? '').toString();
        _chapterPath = (item['chapter_path'] ?? '').toString();
        _images = images.cast<Map<String, dynamic>>();
        final String name = (item['chapter_name'] ?? '').toString();
        if (name.isNotEmpty) _currentTitle = 'Chap $name';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lỗi: $_error', style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: _fetchChapter, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : _buildReaderWithOverlay(),
    );
  }

  Widget _buildReaderWithOverlay() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        children: [
          _buildImageList(),
          if (_showControls) _buildTopBar(),
          if (_showControls) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildImageList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _images.length,
          itemBuilder: (context, index) {
            final m = _images[index];
            final String file = (m['image_file'] ?? '').toString();
            final String url = '$_cdn/$_chapterPath/$file';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Image.network(
                url,
                width: maxWidth,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: maxWidth,
                    height: maxWidth * 1.4,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: maxWidth,
                    height: 120,
                    child: const Center(
                      child: Text('Không tải được ảnh', style: TextStyle(color: Colors.white70)),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.only(top: 32, left: 8, right: 8, bottom: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                _currentTitle.isNotEmpty ? _currentTitle : (widget.title ?? ''),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool hasChapters = (widget.chapters != null && widget.chapters!.isNotEmpty);
    final bool canPrev = hasChapters && _currentIndex > 0;
    final bool canNext = hasChapters && _currentIndex < widget.chapters!.length - 1;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              onPressed: canPrev ? _goPrev : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasChapters ? _openChapterPicker : null,
                icon: const Icon(Icons.menu_book),
                label: Text(hasChapters ? 'Chọn chương' : 'Không có danh sách chương'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              onPressed: canNext ? _goNext : null,
            ),
          ],
        ),
      ),
    );
  }

  void _goPrev() {
    if (widget.chapters == null) return;
    if (_currentIndex <= 0) return;
    _loadByIndex(_currentIndex - 1);
  }

  void _goNext() {
    if (widget.chapters == null) return;
    if (_currentIndex >= widget.chapters!.length - 1) return;
    _loadByIndex(_currentIndex + 1);
  }

  void _openChapterPicker() {
    if (widget.chapters == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            itemCount: widget.chapters!.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white24, height: 1),
            itemBuilder: (context, index) {
              final m = widget.chapters![index];
              final name = (m['chapter_name'] ?? '').toString();
              final apiUrl = (m['chapter_api_data'] ?? '').toString();
              final bool selected = index == _currentIndex;
              return ListTile(
                title: Text('Chap $name', style: TextStyle(color: selected ? Colors.amber : Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  if (apiUrl.isEmpty) return;
                  _loadByIndex(index);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _loadByIndex(int index) {
    if (widget.chapters == null) return;
    final m = widget.chapters![index];
    final apiUrl = (m['chapter_api_data'] ?? '').toString();
    final name = (m['chapter_name'] ?? '').toString();
    if (apiUrl.isEmpty) return;
    setState(() {
      _currentIndex = index;
      _currentApiUrl = apiUrl;
      _currentTitle = 'Chap $name';
    });
    _fetchChapter();
  }
}


